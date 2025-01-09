-- 5. Найти пользователей, у которых нет активных сессий
SELECT  id AS user_id, email, username
FROM  users
WHERE 
    NOT EXISTS (
        SELECT 1
        FROM user_sessions
        WHERE user_sessions.user_id = users.id
          AND user_sessions.status = 'LOGGED_IN'
    );