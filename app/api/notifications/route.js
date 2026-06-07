import { PrismaClient } from '@prisma/client';
import { getSession, corsHeaders } from '../../../lib/auth';

const prisma = new PrismaClient();

export async function OPTIONS() {
  return new Response(null, { status: 204, headers: corsHeaders });
}

export async function GET(request) {
  try {
    const session = await getSession(request);
    if (!session) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: corsHeaders });

    let notifications = [];

    if (session.role === 'STUDENT') {
      const student = await prisma.user.findUnique({
        where: { id: session.id },
        include: { enrolledIn: { select: { id: true } } }
      });

      if (!student) {
        return new Response(JSON.stringify({ error: 'User not found. Please log in again.' }), { status: 404, headers: corsHeaders });
      }

      const courseIds = student.enrolledIn.map(c => c.id);
      notifications = await prisma.notification.findMany({
        where: { course_id: { in: courseIds } },
        orderBy: { created_at: 'desc' },
        take: 20,
        include: { course: { select: { code: true, name: true } } }
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
        take: 20,
        include: { course: { select: { code: true, name: true } } }
      });
    } else {
      notifications = await prisma.notification.findMany({
        orderBy: { created_at: 'desc' },
        take: 20,
        include: { course: { select: { code: true, name: true } } }
      });
    }

    return new Response(JSON.stringify(notifications), { status: 200, headers: corsHeaders });
  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ error: 'Failed to fetch notifications' }), { status: 500, headers: corsHeaders });
  }
}
