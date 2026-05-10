import prisma from '../../../../lib/prisma';
import { cookies } from 'next/headers';

export async function POST(request) {
  try {
    const sessionCookie = (await cookies()).get('session');
    if (!sessionCookie) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 });
    const session = JSON.parse(sessionCookie.value);

    const { academic_level, semester, courseIds } = await request.json();

    const dataToUpdate = {};
    if (academic_level !== undefined) dataToUpdate.academic_level = academic_level;
    if (semester !== undefined) dataToUpdate.semester = semester;

    if (courseIds && Array.isArray(courseIds)) {
      dataToUpdate.enrolledIn = { set: [], connect: courseIds.map(id => ({ id })) };
    }

    const updatedUser = await prisma.user.update({
      where: { id: session.id },
      data: dataToUpdate,
      include: { enrolledIn: true }
    });

    return new Response(JSON.stringify({ success: true, user: updatedUser }), { status: 200 });
  } catch (error) {
    console.error('Settings update error:', error);
    return new Response(JSON.stringify({ error: 'Failed to save settings' }), { status: 500 });
  }
}

export async function GET() {
  try {
    const sessionCookie = (await cookies()).get('session');
    if (!sessionCookie) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 });
    const session = JSON.parse(sessionCookie.value);

    const user = await prisma.user.findUnique({
      where: { id: session.id },
      include: { enrolledIn: { select: { id: true } } }
    });

    const allCourses = await prisma.course.findMany({ include: { lecturer: true } });

    return new Response(JSON.stringify({ user, allCourses }), { status: 200 });
  } catch (error) {
    return new Response(JSON.stringify({ error: 'Failed to fetch settings data' }), { status: 500 });
  }
}
