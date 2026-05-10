import { PrismaClient } from '@prisma/client';
import { cookies } from 'next/headers';

const prisma = new PrismaClient();

export async function POST(request) {
  try {
    const sessionCookie = (await cookies()).get('session');
    if (!sessionCookie) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 });
    const session = JSON.parse(sessionCookie.value);

    if (session.role !== 'ADMIN') {
      return new Response(JSON.stringify({ error: 'Forbidden' }), { status: 403 });
    }

    const { code, name, enrolled_count, lecturer_id } = await request.json();

    const course = await prisma.course.create({
      data: { code, name, enrolled_count, lecturer_id },
      include: { lecturer: true }
    });

    return new Response(JSON.stringify(course), { status: 201 });
  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ error: 'Failed to create course' }), { status: 500 });
  }
}

export async function DELETE(request) {
  try {
    const sessionCookie = (await cookies()).get('session');
    if (!sessionCookie) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 });
    const session = JSON.parse(sessionCookie.value);

    if (session.role !== 'ADMIN') {
      return new Response(JSON.stringify({ error: 'Forbidden' }), { status: 403 });
    }

    const { searchParams } = new URL(request.url);
    const id = searchParams.get('id');

    if (!id) return new Response(JSON.stringify({ error: 'Course ID is required' }), { status: 400 });

    await prisma.$transaction([
      prisma.timetableEntry.deleteMany({ where: { course_id: id } }),
      prisma.reservation.deleteMany({ where: { course_id: id } }),
      prisma.notification.deleteMany({ where: { course_id: id } }),
      prisma.course.delete({ where: { id } })
    ]);

    return new Response(JSON.stringify({ success: true }), { status: 200 });
  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ error: error.message || 'Failed to delete course' }), { status: 500 });
  }
}
