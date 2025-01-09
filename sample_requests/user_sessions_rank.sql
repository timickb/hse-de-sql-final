-- 4. Найти пользователей с их последними активными сессиями и добавить информацию о ранге активности (на основе времени создания сессий)
SELECT
    u.id AS user_id,
    u.email,
    u.username,
    s.id AS session_id,
    s.status,
    s.created_at,
    RANK() OVER (PARTITION BY u.id ORDER BY s.created_at DESC) AS session_rank
FROM users u
JOIN user_sessions s ON u.id = s.user_id
WHERE u.enabled = TRUE
ORDER BY u.id, session_rank;