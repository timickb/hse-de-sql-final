-- 3. Посчитать активные сессии для каждого пользователя
WITH active_sessions AS (
    SELECT user_id, COUNT(*) AS session_count
    FROM user_sessions
    WHERE status = 'LOGGED_IN'
    GROUP BY user_id
)
SELECT
    u.id AS user_id,
    u.email,
    u.username,
    a.session_count
FROM users u
JOIN active_sessions a ON u.id = a.user_id
WHERE u.enabled = TRUE
ORDER BY a.session_count DESC;