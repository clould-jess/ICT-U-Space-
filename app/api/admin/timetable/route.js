import prisma from '../../../../lib/prisma';
import { cookies } from 'next/headers';

async function requireAdmin() {
  const sessionCookie = (await cookies()).get('session');
  if (!sessionCookie) return null;
  const session = JSON.parse(sessionCookie.value);
  return session.role === 'ADMIN' ? session : null;
}

export async function GET() {
  try {
    const admin = await requireAdmin();
    if (!admin) return new Response(JSON.stringify({ error: 'Forbidden' }), { status: 403 });

    const entries = await prisma.timetableEntry.findMany({
      include: {
        hall: true,
        course: { include: { lecturer: true } }
      },
      orderBy: [{ day_of_week: 'asc' }, { start_time: 'asc' }]
    });

    return new Response(JSON.stringify(entries), { status: 200 });
  } catch (error) {
    return new Response(JSON.stringify({ error: 'Failed to fetch timetable' }), { status: 500 });
  }
}

export async function POST(request) {
  try {
    const admin = await requireAdmin();
    if (!admin) return new Response(JSON.stringify({ error: 'Forbidden' }), { status: 403 });

    const { hall_id, course_id, day_of_week, start_time, end_time } = await request.json();

    if (!hall_id || !course_id || !day_of_week || !start_time || !end_time) {
      return new Response(JSON.stringify({ error: 'All fields are required' }), { status: 400 });
    }

    if (start_time >= end_time) {
      return new Response(JSON.stringify({ error: 'End time must be after start time' }), { status: 400 });
    }

    // Check for conflicts
    const conflict = await prisma.timetableEntry.findFirst({
      where: {
        hall_id,
        day_of_week,
        AND: [{ start_time: { lt: end_time } }, { end_time: { gt: start_time } }]
      }
    });

    if (conflict) {
      return new Response(JSON.stringify({ error: 'This hall is already scheduled at that time' }), { status: 409 });
    }

    const entry = await prisma.timetableEntry.create({
      data: { hall_id, course_id, day_of_week, start_time, end_time },
      include: { hall: true, course: { include: { lecturer: true } } }
    });

    return new Response(JSON.stringify(entry), { status: 201 });
  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ error: 'Failed to create timetable entry' }), { status: 500 });
  }
}

export async function DELETE(request) {
  try {
    const admin = await requireAdmin();
    if (!admin) return new Response(JSON.stringify({ error: 'Forbidden' }), { status: 403 });

    const { id } = await request.json();
    if (!id) return new Response(JSON.stringify({ error: 'ID required' }), { status: 400 });

    await prisma.timetableEntry.delete({ where: { id } });
    return new Response(JSON.stringify({ success: true }), { status: 200 });
  } catch (error) {
    return new Response(JSON.stringify({ error: 'Failed to delete timetable entry' }), { status: 500 });
  }
}
