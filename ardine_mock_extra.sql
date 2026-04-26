-- ============================================================
-- Ardine Mock Data — เพิ่มเติม: invites + sessions
-- ต่อจาก ardine_mock_data_v2.sql
-- ============================================================
-- UUID prefix ที่ใช้ใหม่:
--   a3... = invites
--   b3... = sessions
-- ============================================================

-- ============================================================
-- 13. INVITES
-- สถานการณ์จำลอง:
--   - PixelCraft เชิญ designer คนใหม่ (pending, ยังไม่ accept)
--   - PixelCraft เชิญ PM แต่ token หมดอายุแล้ว (expired)
--   - PixelCraft เชิญ billing คนใหม่ (accepted แล้ว)
--   - DevOps Squad เชิญ DevOps engineer (pending)
--   - DevOps Squad เชิญ viewer จาก client (cancelled / expired)
-- ============================================================
INSERT INTO invites (id, team_id, email, role, token, expires_at, accepted_at, created_at) VALUES

-- PixelCraft: เชิญ designer คนใหม่ — pending รอ accept
(
  'a3000000-0000-0000-0000-000000000001',
  'a1000000-0000-0000-0000-000000000001',
  'grace@design.io',
  'MEMBER',
  'tok_pixelcraft_grace_abc123def456',
  NOW() + INTERVAL '5 days',   -- ยังไม่หมดอายุ
  NULL,                          -- ยังไม่ accept
  NOW() - INTERVAL '2 days'
),

-- PixelCraft: เชิญ PM — expired ไม่มาคลิกลิงก์ทัน
(
  'a3000000-0000-0000-0000-000000000002',
  'a1000000-0000-0000-0000-000000000001',
  'henry.pm@outlook.com',
  'MEMBER',
  'tok_pixelcraft_henry_xyz789ghi012',
  NOW() - INTERVAL '3 days',   -- หมดอายุแล้ว
  NULL,                          -- ไม่เคย accept
  NOW() - INTERVAL '10 days'
),

-- PixelCraft: เชิญ billing manager — accepted แล้ว (Fiona รับ role นี้)
(
  'a3000000-0000-0000-0000-000000000003',
  'a1000000-0000-0000-0000-000000000001',
  'fiona@pixelcraft.io',
  'BILLING',
  'tok_pixelcraft_fiona_jkl345mno678',
  NOW() - INTERVAL '25 days',  -- หมดอายุแล้ว แต่ accept ก่อน
  NOW() - INTERVAL '28 days',  -- accept ก่อนหมดอายุ
  NOW() - INTERVAL '35 days'
),

-- PixelCraft: เชิญ senior dev — pending ส่งไปเมื่อวาน
(
  'a3000000-0000-0000-0000-000000000004',
  'a1000000-0000-0000-0000-000000000001',
  'ivan.dev@gmail.com',
  'MEMBER',
  'tok_pixelcraft_ivan_pqr901stu234',
  NOW() + INTERVAL '6 days',
  NULL,
  NOW() - INTERVAL '1 day'
),

-- DevOps Squad: เชิญ DevOps engineer — pending
(
  'a3000000-0000-0000-0000-000000000005',
  'a1000000-0000-0000-0000-000000000002',
  'julia.ops@techcorp.com',
  'MEMBER',
  'tok_devops_julia_vwx567yza890',
  NOW() + INTERVAL '4 days',
  NULL,
  NOW() - INTERVAL '3 days'
),

-- DevOps Squad: เชิญ client viewer (CloudNine ขอดู project) — expired
(
  'a3000000-0000-0000-0000-000000000006',
  'a1000000-0000-0000-0000-000000000002',
  'raj.patel@cloudnine.sg',
  'VIEWER',
  'tok_devops_raj_bcd123efg456',
  NOW() - INTERVAL '15 days',  -- หมดอายุแล้ว
  NULL,                          -- ไม่ได้ accept
  NOW() - INTERVAL '22 days'
),

-- DevOps Squad: เชิญ admin คนใหม่ — accept แล้ว
(
  'a3000000-0000-0000-0000-000000000007',
  'a1000000-0000-0000-0000-000000000002',
  'evan@devops.io',
  'MEMBER',
  'tok_devops_evan_hij789klm012',
  NOW() - INTERVAL '55 days',
  NOW() - INTERVAL '58 days',   -- accept ก่อน expired
  NOW() - INTERVAL '65 days'
);

-- ============================================================
-- 14. SESSIONS
-- สถานการณ์จำลอง:
--   - Alice login อยู่ (active session)
--   - Bob login อยู่ (active session)
--   - Charlie เคย login แต่ session หมดอายุแล้ว
--   - Diana login อยู่ (active)
--   - Evan session หมดอายุ
--   - Fiona มี 2 session (login จาก 2 device)
-- ============================================================
INSERT INTO sessions (id, user_id, expires_at, created_at) VALUES

-- Alice — active session (login จาก laptop)
(
  'sess_alice_laptop_abc123def456ghi789',
  'b1000000-0000-0000-0000-000000000001',
  NOW() + INTERVAL '7 days',
  NOW() - INTERVAL '1 day'
),

-- Bob — active session
(
  'sess_bob_chrome_jkl012mno345pqr678',
  'b1000000-0000-0000-0000-000000000002',
  NOW() + INTERVAL '5 days',
  NOW() - INTERVAL '2 days'
),

-- Charlie — session หมดอายุ (ไม่ได้ login มานาน)
(
  'sess_charlie_old_stu901vwx234yza567',
  'b1000000-0000-0000-0000-000000000003',
  NOW() - INTERVAL '10 days',  -- expired
  NOW() - INTERVAL '40 days'
),

-- Charlie — session ใหม่ที่ยัง active
(
  'sess_charlie_new_bcd890efg123hij456',
  'b1000000-0000-0000-0000-000000000003',
  NOW() + INTERVAL '6 days',
  NOW() - INTERVAL '3 hours'
),

-- Diana — active session
(
  'sess_diana_safari_klm789nop012qrs345',
  'b1000000-0000-0000-0000-000000000004',
  NOW() + INTERVAL '7 days',
  NOW() - INTERVAL '5 hours'
),

-- Evan — session หมดอายุ
(
  'sess_evan_firefox_tuv678wxy901zab234',
  'b1000000-0000-0000-0000-000000000005',
  NOW() - INTERVAL '2 days',   -- expired
  NOW() - INTERVAL '16 days'
),

-- Fiona — login จาก laptop (active)
(
  'sess_fiona_laptop_cde567fgh890ijk123',
  'b1000000-0000-0000-0000-000000000006',
  NOW() + INTERVAL '7 days',
  NOW() - INTERVAL '6 hours'
),

-- Fiona — login จาก mobile (active) — 2 sessions พร้อมกัน
(
  'sess_fiona_mobile_lmn456opq789rst012',
  'b1000000-0000-0000-0000-000000000006',
  NOW() + INTERVAL '3 days',
  NOW() - INTERVAL '1 hour'
);

-- ============================================================
-- ตัวอย่าง queries สำหรับ invites และ sessions
-- ============================================================
/*
Q: "invitation ที่ยังรอการตอบรับและยังไม่หมดอายุ"
SELECT i.email, i.role, t.name AS team, i.expires_at,
       i.expires_at::date - NOW()::date AS days_left
FROM invites i
JOIN teams t ON i.team_id = t.id
WHERE i.accepted_at IS NULL
  AND i.expires_at > NOW()
ORDER BY i.expires_at;

Q: "invitation ที่หมดอายุแล้วและไม่ได้ accept"
SELECT i.email, i.role, t.name AS team,
       NOW()::date - i.expires_at::date AS days_expired
FROM invites i
JOIN teams t ON i.team_id = t.id
WHERE i.accepted_at IS NULL
  AND i.expires_at < NOW()
ORDER BY days_expired DESC;

Q: "แต่ละ team มี pending invitation กี่คน"
SELECT t.name AS team, COUNT(*) AS pending_invites
FROM invites i
JOIN teams t ON i.team_id = t.id
WHERE i.accepted_at IS NULL
  AND i.expires_at > NOW()
GROUP BY t.name;

Q: "user ที่มี active session อยู่ตอนนี้"
SELECT u.name, u.email, COUNT(s.id) AS active_sessions,
       MAX(s.created_at) AS last_login
FROM sessions s
JOIN users u ON s.user_id = u.id
WHERE s.expires_at > NOW()
GROUP BY u.name, u.email
ORDER BY last_login DESC;

Q: "user ที่ login จากหลาย device พร้อมกัน"
SELECT u.name, COUNT(s.id) AS session_count
FROM sessions s
JOIN users u ON s.user_id = u.id
WHERE s.expires_at > NOW()
GROUP BY u.name
HAVING COUNT(s.id) > 1;

Q: "session ที่หมดอายุแล้วมีทั้งหมดกี่ session"
SELECT COUNT(*) AS expired_sessions
FROM sessions
WHERE expires_at < NOW();
*/
