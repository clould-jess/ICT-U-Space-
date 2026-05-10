import prisma from '../../lib/prisma';
import webpush from 'web-push';

// Configure web-push once
if (process.env.NEXT_PUBLIC_VAPID_PUBLIC_KEY && process.env.VAPID_PRIVATE_KEY) {
  webpush.setVapidDetails(
    'mailto:admin@campus-space.edu',
    process.env.NEXT_PUBLIC_VAPID_PUBLIC_KEY,
    process.env.VAPID_PRIVATE_KEY
  );
}

/**
 * Service Layer demonstrating Encapsulation
 */
class NotificationService {
  
  // Public method
  async notifyCourseStudents(course, hall, date, startTime, endTime) {
    const message = `A new reservation for ${course.code} has been booked in ${hall.name} on ${date} from ${startTime} to ${endTime}.`;
    
    // 1. Create DB Notification
    await this.#createDatabaseNotification(course.id, message);

    // 2. Dispatch Push Payload
    await this.#dispatchPushNotifications(course, hall, date);
  }

  // Private method (Encapsulation: hiding implementation details)
  async #createDatabaseNotification(courseId, message) {
    await prisma.notification.create({
      data: {
        message: message,
        course_id: courseId
      }
    });
  }

  // Private method (Encapsulation: hiding web push complexity)
  async #dispatchPushNotifications(course, hall, date) {
    if (!process.env.NEXT_PUBLIC_VAPID_PUBLIC_KEY) return;

    const enrolledStudents = await prisma.user.findMany({
      where: {
        enrolledIn: { some: { id: course.id } },
        push_subscription: { not: null }
      }
    });

    const payload = JSON.stringify({
      title: 'New Class Reservation!',
      body: `${course.code} has been booked in ${hall.name} on ${date}.`
    });

    for (const student of enrolledStudents) {
      try {
        const sub = JSON.parse(student.push_subscription);
        await webpush.sendNotification(sub, payload);
      } catch (err) {
        console.error('Push error for student', student.id, err);
      }
    }
  }
}

export default NotificationService;
