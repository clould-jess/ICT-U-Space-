import { PrismaClient } from '@prisma/client';
import { getSession, corsHeaders } from '../../../../lib/auth';

const prisma = new PrismaClient();

export async function OPTIONS() {
  return new Response(null, { status: 204, headers: corsHeaders });
}

export async function POST(request) {
  try {
    const session = await getSession(request);
    if (!session) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: corsHeaders });

    const { academic_level, semester, major, courseIds } = await request.json();

    const dataToUpdate = {};
    if (academic_level !== undefined) dataToUpdate.academic_level = academic_level;
    if (semester !== undefined) dataToUpdate.semester = semester;
    if (major !== undefined) dataToUpdate.major = major;

    if (courseIds && Array.isArray(courseIds)) {
      dataToUpdate.enrolledIn = {
        set: [],
        connect: courseIds.map(id => ({ id }))
      };
    }

    // Get old enrollments before update so we can recalculate counts for removed courses too
    const userBefore = await prisma.user.findUnique({
      where: { id: session.id },
      include: { enrolledIn: { select: { id: true } } }
    });
    const oldCourseIds = userBefore?.enrolledIn.map(c => c.id) ?? [];

    const updatedUser = await prisma.user.update({
      where: { id: session.id },
      data: dataToUpdate,
      include: { enrolledIn: true }
    });

    // Recalculate enrolled_count for all affected courses
    if (courseIds && Array.isArray(courseIds)) {
      const affectedIds = [...new Set([...oldCourseIds, ...courseIds])];
      await Promise.all(affectedIds.map(async (id) => {
        const count = await prisma.user.count({
          where: { enrolledIn: { some: { id } } }
        });
        await prisma.course.update({ where: { id }, data: { enrolled_count: count } });
      }));
    }

    return new Response(JSON.stringify({ success: true, user: updatedUser }), { status: 200, headers: corsHeaders });
  } catch (error) {
    console.error('Settings update error:', error);
    return new Response(JSON.stringify({ error: 'Failed to save settings' }), { status: 500, headers: corsHeaders });
  }
}

export async function GET(request) {
  try {
    const session = await getSession(request);
    if (!session) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: corsHeaders });

    const user = await prisma.user.findUnique({
      where: { id: session.id },
      select: {
        id: true,
        academic_level: true,
        semester: true,
        major: true,
        enrolledIn: { select: { id: true } },
      },
    });

    // Fetch all available courses so the frontend can display them for enrollment
    const allCourses = await prisma.course.findMany({
      include: {
        lecturer: { select: { id: true, name: true } },
        _count: { select: { students: true } },
      }
    });

    return new Response(JSON.stringify({ user, allCourses }), { status: 200, headers: corsHeaders });
  } catch (error) {
    return new Response(JSON.stringify({ error: 'Failed to fetch settings data' }), { status: 500, headers: corsHeaders });
  }
}
