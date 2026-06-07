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

    let timetableEntries = [];

    if (session.role === 'STUDENT') {
      const student = await prisma.user.findUnique({
        where: { id: session.id },
        include: { enrolledIn: { select: { id: true } } }
      });

      if (!student) {
        return new Response(JSON.stringify({ error: 'User not found. Please log in again.' }), { status: 404, headers: corsHeaders });
      }

      const courseIds = student.enrolledIn.map(c => c.id);
      
      timetableEntries = await prisma.timetableEntry.findMany({
        where: { course_id: { in: courseIds } },
        include: {
          course: { select: { code: true, name: true } },
          hall: { select: { name: true } }
        }
      });
    } else if (session.role === 'LECTURER') {
      const courses = await prisma.course.findMany({
        where: { lecturer_id: session.id },
        select: { id: true }
      });
      const courseIds = courses.map(c => c.id);
      
      timetableEntries = await prisma.timetableEntry.findMany({
        where: { course_id: { in: courseIds } },
        include: {
          course: { select: { code: true, name: true } },
          hall: { select: { name: true } }
        }
      });
    } else {
      timetableEntries = await prisma.timetableEntry.findMany({
        include: {
          course: { select: { code: true, name: true } },
          hall: { select: { name: true } }
        }
      });
    }

    return new Response(JSON.stringify(timetableEntries), { status: 200, headers: corsHeaders });
  } catch (error) {
    console.error('Error fetching timetable:', error);
    return new Response(JSON.stringify({ error: 'Failed to fetch timetable' }), { status: 500, headers: corsHeaders });
  }
}
