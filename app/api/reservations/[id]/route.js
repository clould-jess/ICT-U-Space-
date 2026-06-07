import { PrismaClient } from '@prisma/client';
import { getSession, corsHeaders } from '../../../../lib/auth';

const prisma = new PrismaClient();

export async function OPTIONS() {
  return new Response(null, { status: 204, headers: corsHeaders });
}

export async function DELETE(request, { params }) {
  try {
    const session = await getSession(request);
    if (!session) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: corsHeaders });

    const { id } = await params;

    const reservation = await prisma.reservation.findUnique({
      where: { id },
      include: { course: { select: { lecturer_id: true, delegate_id: true } } },
    });
    if (!reservation) {
      return new Response(JSON.stringify({ error: 'Reservation not found' }), { status: 404, headers: corsHeaders });
    }

    const isAdmin = session.role === 'ADMIN';
    const isLecturer = reservation.course?.lecturer_id === session.id;
    const isPrefect = reservation.course?.delegate_id === session.id;

    if (!isAdmin && !isLecturer && !isPrefect) {
      return new Response(
        JSON.stringify({ error: 'Only the admin, the course lecturer, or the class delegate can unbook a hall.' }),
        { status: 403, headers: corsHeaders }
      );
    }

    await prisma.reservation.delete({ where: { id } });
    return new Response(JSON.stringify({ success: true }), { status: 200, headers: corsHeaders });

  } catch (error) {
    console.error('Reservation deletion error:', error);
    return new Response(JSON.stringify({ error: 'Internal Server Error' }), { status: 500, headers: corsHeaders });
  }
}
