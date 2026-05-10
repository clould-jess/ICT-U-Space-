import { PrismaClient } from '@prisma/client';
import { cookies } from 'next/headers';

const prisma = new PrismaClient();

export async function GET() {
  try {
    const sessionCookie = (await cookies()).get('session');
    if (!sessionCookie) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 });
    const session = JSON.parse(sessionCookie.value);

    let notifications = [];

    if (session.role === 'STUDENT') {
      const student = await prisma.user.findUnique({
        where: { id: session.id },
        include: { enrolledIn: { select: { id: true } } }
      });

      if (!student) {
        return new Response(JSON.stringify({ error: 'User not found. Please log in again.' }), { status: 404 });
      }

      const courseIds = student.enrolledIn.map(c => c.id);

      notifications = await prisma.notification.findMany({
        where: { course_id: { in: courseIds } },
        orderBy: { created_at: 'desc' },
        take: 20
      });
    } else if (session.role === 'LECTURER') {
      const courses = await prisma.course.findMany({
        where: { lecturer_id: session.id },
        select: { id: true }
      });
      const courseIds = courses.map(c => c.id);

      notifications = await prisma.notification.findMany({
        where: { course_id: { in: courseIds } },
        orderBy: { created_at: 'desc' },
        take: 20
      });
    } else {
      notifications = await prisma.notification.findMany({
        orderBy: { created_at: 'desc' },
        take: 20
      });
    }

    return new Response(JSON.stringify(notifications), { status: 200 });
  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ error: 'Failed to fetch notifications' }), { status: 500 });
  }
}
