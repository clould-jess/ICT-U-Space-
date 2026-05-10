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
    const { date, start_time, end_time, course_id, hall_id, force_booking, reserved_by } = bookingData;

    const hall = await prisma.hall.findUnique({ where: { id: hall_id } });
    const course = await prisma.course.findUnique({ where: { id: course_id } });

    if (!hall || !course) {
      throw new Error('Invalid hall or course');
    }

    // Abstraction: Hiding smart capacity logic inside a private method
    if (!force_booking) {
      await this.#checkCapacityConstraints(hall, course, date, start_time, end_time);
    }

    // Proceed with database creation
    const reservation = await prisma.reservation.create({
      data: {
        date,
        start_time,
        end_time,
        status: 'CONFIRMED',
        hall_id,
        course_id,
        reserved_by
      }
    });

    // Delegate notification logic to another service
    await this.notificationService.notifyCourseStudents(course, hall, date, start_time, end_time);

    return reservation;
  }

  /**
   * Private method (Encapsulation)
   */
  async #checkCapacityConstraints(hall, course, date, start_time, end_time) {
    if (hall.capacity >= course.enrolled_count) return; // All good

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

    if (availableAlternatives.length > 0) {
      const error = new Error('CAPACITY_WARNING');
      error.details = {
        message: `This hall (${hall.capacity} seats) is too small for the class size (${course.enrolled_count} students). We found better alternatives!`,
        alternatives: availableAlternatives
      };
      throw error;
    }
  }
}

export default ReservationService;
