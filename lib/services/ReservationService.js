import prisma from '../../lib/prisma';
import NotificationService from './NotificationService';

/**
 * Service Layer demonstrating Encapsulation and Abstraction
 */
class ReservationService {
  constructor() {
    this.notificationService = new NotificationService();
  }

  /**
   * Public method handling the entire booking business logic
   */
  async bookRoom(bookingData) {
    const { date, start_time, end_time, course_id, hall_id, force_booking, reserved_by, booking_key, event_name } = bookingData;

    const user = await prisma.user.findUnique({ where: { id: reserved_by } });
    if (!user) throw new Error('User not found');

    // 1. Booking Key Verification
    if (user.role !== 'ADMIN' || booking_key) {
      if (!booking_key) throw new Error('Booking key is required');
      if (user.booking_key && user.booking_key !== booking_key) {
        throw new Error('Invalid booking key provided');
      } else if (!user.booking_key) {
        // Save the key for future use if not present
        await prisma.user.update({ where: { id: user.id }, data: { booking_key } });
      }
    }

    const hall = await prisma.hall.findUnique({ where: { id: hall_id } });
    if (!hall) throw new Error('Invalid hall');

    let course = null;
    let type = 'CLASS';

    // 2. Role-based Restrictions & Admin Events
    if (user.role === 'ADMIN' && event_name) {
      type = 'EVENT';
      // course_id can be null for admin events
    } else {
      if (!course_id) throw new Error('Course ID is required for standard reservations');
      course = await prisma.course.findUnique({ where: { id: course_id } });
      if (!course) throw new Error('Invalid course');

      if (user.role === 'LECTURER' && course.lecturer_id !== user.id) {
        throw new Error('You can only book halls for courses you are assigned to.');
      }
      if (user.role === 'PREFECT' && course.delegate_id !== user.id) {
        throw new Error('You can only book halls for courses you are the delegate for.');
      }
    }

    // Abstraction: Hiding smart capacity logic inside a private method (only for classes)
    if (!force_booking && type === 'CLASS') {
      const recommendations = await this.getRecommendations(course.id, date, start_time, end_time);
      
      // If the currently selected hall is not in the recommendations (or capacity is just generally smaller than enrolled), throw warning
      // Wait, we should just check if hall.capacity < course.enrolled_count.
      if (hall.capacity < course.enrolled_count) {
        if (recommendations.length > 0) {
          const error = new Error('CAPACITY_WARNING');
          error.details = {
            message: `This hall (${hall.capacity} seats) is too small for the class size (${course.enrolled_count} students). We found better alternatives!`,
            alternatives: recommendations
          };
          throw error;
        } else {
          // It's too small and no alternatives exist, let them book anyway or block?
          // Since there are no alternatives, we'll let it slide or they must use force_booking.
          // In standard flow, they would use force_booking to override.
          const error = new Error('CAPACITY_WARNING');
          error.details = {
            message: `This hall (${hall.capacity} seats) is too small, but no better alternatives are available. Proceed with caution.`,
            alternatives: []
          };
          throw error;
        }
      }
    }

    // Check for overlaps, especially admin reservations which cannot be overridden
    const overlapping = await prisma.reservation.findMany({
      where: {
        hall_id,
        date,
        status: 'CONFIRMED',
        AND: [{ start_time: { lt: end_time } }, { end_time: { gt: start_time } }]
      }
    });

    if (overlapping.length > 0) {
      throw new Error('The hall is already booked during this time.');
    }

    // Proceed with database creation
    const reservation = await prisma.reservation.create({
      data: {
        date,
        start_time,
        end_time,
        status: 'CONFIRMED',
        hall_id,
        course_id: type === 'CLASS' ? course_id : null,
        reserved_by,
        type,
        event_name: type === 'EVENT' ? event_name : null
      }
    });

    // Delegate notification logic to another service
    if (type === 'CLASS') {
      await this.notificationService.notifyCourseStudents(course, hall, date, start_time, end_time);
    }

    return reservation;
  }

  /**
   * Public method for smart recommendation algorithm
   */
  async getRecommendations(course_id, date, start_time, end_time) {
    const course = await prisma.course.findUnique({ where: { id: course_id } });
    if (!course) return [];

    const bigHalls = await prisma.hall.findMany({
      where: { capacity: { gte: course.enrolled_count } }
    });
    
    const dayOfWeek = new Date(date).toLocaleDateString('en-US', { weekday: 'long' });
    const availableAlternatives = [];

    for (const h of bigHalls) {
      const timetableConflicts = await prisma.timetableEntry.findMany({
        where: {
          hall_id: h.id,
          day_of_week: dayOfWeek,
          AND: [
            { start_time: { lt: end_time } },
            { end_time: { gt: start_time } }
          ]
        }
      });
      
      const reservationConflicts = await prisma.reservation.findMany({
        where: {
          hall_id: h.id,
          date: date,
          status: 'CONFIRMED',
          AND: [
            { start_time: { lt: end_time } },
            { end_time: { gt: start_time } }
          ]
        }
      });

      if (timetableConflicts.length === 0 && reservationConflicts.length === 0) {
        availableAlternatives.push(h);
      }
    }

    // Sort alternatives to recommend the smallest hall that fits the class (perfect fit)
    availableAlternatives.sort((a, b) => a.capacity - b.capacity);
    return availableAlternatives;
  }
}

export default ReservationService;
