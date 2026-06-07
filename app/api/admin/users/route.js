import { PrismaClient } from '@prisma/client';
import { getSession, corsHeaders } from '../../../../lib/auth';

const prisma = new PrismaClient();

export async function OPTIONS() {
  return new Response(null, { status: 204, headers: corsHeaders });
}

export async function GET(request) {
  try {
    const session = await getSession(request);
    if (!session) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: corsHeaders });

    if (session.role !== 'ADMIN') {
      return new Response(JSON.stringify({ error: 'Forbidden' }), { status: 403, headers: corsHeaders });
    }

    const users = await prisma.user.findMany({
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        matricule: true,
        academic_level: true,
        semester: true,
        coursesTaught: { select: { id: true, code: true, name: true } },
        enrolledIn:    { select: { id: true, code: true, name: true } },
        coursesDelegated: { select: { id: true, code: true, name: true } },
      },
      orderBy: [{ role: 'asc' }, { name: 'asc' }],
    });

    return new Response(JSON.stringify(users), { status: 200, headers: corsHeaders });
  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ error: 'Failed to fetch users' }), { status: 500, headers: corsHeaders });
  }
}
