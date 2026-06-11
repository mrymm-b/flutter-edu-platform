-- Student personal timetable
CREATE TABLE IF NOT EXISTS public.student_schedule (
  id           TEXT        PRIMARY KEY,
  student_id   UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  day_of_week  INTEGER     NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
  time         TEXT        NOT NULL,
  end_time     TEXT        NOT NULL DEFAULT '',
  subject      TEXT        NOT NULL,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.student_schedule ENABLE ROW LEVEL SECURITY;

CREATE POLICY "students_manage_own_schedule"
  ON public.student_schedule
  FOR ALL
  TO authenticated
  USING  (student_id = auth.uid())
  WITH CHECK (student_id = auth.uid());
