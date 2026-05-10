import prisma from '../../../../lib/prisma';
import { cookies } from 'next/headers';

async function requireAdmin() {
  const sessionCookie = (await cookies()).get('session');
  if (!sessionCookie) return null;
  const session = JSON.parse(sessionCookie.value);
  return session.role === 'ADMIN' ? session : null;
}

export async function POST(request) {
  try {
    const admin = await requireAdmin();
    if (!admin) return new Response(JSON.stringify({ error: 'Forbidden' }), { status: 403 });

    const { code, name, enrolled_count, lecturer_id } = await request.json();

    if (!code || !name || !enrolled_count || !lecturer_id) {
      return new Response(JSON.stringify({ error: 'Missing required fields' }), { status: 400 });
    }

    const course = await prisma.course.create({
      data: { code, name, enrolled_count: parseInt(enrolled_count), lecturer_id },
      include: { lecturer: true }
    });

    return new Response(JSON.stringify(course), { status: 201 });
  } catch (error) {
    console.error(error);
    if (error.code === 'P2002') {
      return new Response(JSON.stringify({ error: 'Course code already exists' }), { status: 409 });
    }
    return new Response(JSON.stringify({ error: 'Failed to create course' }), { status: 500 });
  }
}

export async function DELETE(request) {
  try {
    const admin = await requireAdmin();
    if (!admin) return new Response(JSON.stringify({ error: 'Forbidden' }), { status: 403 });

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
