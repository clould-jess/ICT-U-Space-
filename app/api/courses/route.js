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

    const courses = await prisma.course.findMany({
      where: session.role === 'LECTURER' ? { lecturer_id: session.id } : undefined,
      include: {
        lecturer: { select: { id: true, name: true } },
        delegate: { select: { id: true, name: true } },
        _count: { select: { students: true } },
      },
    });

    return new Response(JSON.stringify(courses), { status: 200, headers: corsHeaders });
  } catch (error) {
    return new Response(JSON.stringify({ error: 'Failed to fetch courses' }), { status: 500, headers: corsHeaders });
  }
}
