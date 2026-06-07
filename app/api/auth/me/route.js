import { PrismaClient } from '@prisma/client';
import { getSession, corsHeaders } from '../../../../lib/auth';

const prisma = new PrismaClient();

export async function OPTIONS() {
  return new Response(null, { status: 204, headers: corsHeaders });
}

export async function GET(request) {
  try {
    const session = await getSession(request);
    if (!session) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: corsHeaders });
    }

    const user = await prisma.user.findUnique({
      where: { id: session.id },
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        matricule: true,
        academic_level: true,
        semester: true,
        booking_key: true,
        enrolledIn: { select: { id: true, name: true, code: true } },
        coursesTaught: { select: { id: true, name: true, code: true } },
      },
    });

    if (!user) {
      return new Response(JSON.stringify({ error: 'User not found' }), { status: 404, headers: corsHeaders });
    }

    return new Response(JSON.stringify(user), { status: 200, headers: corsHeaders });
  } catch (error) {
    console.error('/api/auth/me error:', error);
    return new Response(JSON.stringify({ error: 'Internal server error' }), { status: 500, headers: corsHeaders });
  }
}
