import { PrismaClient } from '@prisma/client';
import { cookies } from 'next/headers';

const prisma = new PrismaClient();

export async function GET() {
  try {
    const sessionCookie = (await cookies()).get('session');
    if (!sessionCookie) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 });
    
    const session = JSON.parse(sessionCookie.value);

    // If lecturer, only return their courses. Otherwise return all courses.
    const courses = await prisma.course.findMany({
      where: session.role === 'LECTURER' ? { lecturer_id: session.id } : undefined,
      include: { lecturer: true }
    });

    return new Response(JSON.stringify(courses), { status: 200 });
  } catch (error) {
    return new Response(JSON.stringify({ error: 'Failed to fetch courses' }), { status: 500 });
  }
}
