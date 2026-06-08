import { PrismaClient } from '@prisma/client';
import { getSession, corsHeaders } from '../../../../lib/auth';

async function requireAdmin() {
  const sessionCookie = (await cookies()).get('session');
  if (!sessionCookie) return null;
  const session = JSON.parse(sessionCookie.value);
  return session.role === 'ADMIN' ? session : null;
}

export async function OPTIONS() {
  return new Response(null, { status: 204, headers: corsHeaders });
}

export async function POST(request) {
  try {
    const session = await getSession(request);
    if (!session) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: corsHeaders });

    if (session.role !== 'ADMIN') {
      return new Response(JSON.stringify({ error: 'Forbidden' }), { status: 403, headers: corsHeaders });
    }

    const { code, name, enrolled_count, lecturer_id } = await request.json();

    if (!code || !name || !enrolled_count || !lecturer_id) {
      return new Response(JSON.stringify({ error: 'Missing required fields' }), { status: 400 });
    }

    const course = await prisma.course.create({
      data: { code, name, enrolled_count: enrolled_count ?? 0, lecturer_id: lecturer_id ?? null },
      include: { lecturer: true }
    });

    return new Response(JSON.stringify(course), { status: 201, headers: corsHeaders });
  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ error: 'Failed to create course' }), { status: 500, headers: corsHeaders });
  }
}

export async function DELETE(request) {
  try {
    const session = await getSession(request);
    if (!session) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: corsHeaders });

    if (session.role !== 'ADMIN') {
      return new Response(JSON.stringify({ error: 'Forbidden' }), { status: 403, headers: corsHeaders });
    }

    const { searchParams } = new URL(request.url);
    const id = searchParams.get('id');

    if (!id) return new Response(JSON.stringify({ error: 'Course ID is required' }), { status: 400, headers: corsHeaders });

    await prisma.$transaction([
      prisma.timetableEntry.deleteMany({ where: { course_id: id } }),
      prisma.reservation.deleteMany({ where: { course_id: id } }),
      prisma.notification.deleteMany({ where: { course_id: id } }),
      prisma.course.delete({ where: { id } })
    ]);

    return new Response(JSON.stringify({ success: true }), { status: 200, headers: corsHeaders });
  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ error: error.message || 'Failed to delete course' }), { status: 500, headers: corsHeaders });
  }
}
