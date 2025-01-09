-- 2. Найти число пользователей каждого пола, если их больше 5-ти
SELECT  gender, COUNT(*) AS count
FROM users
GROUP BY gender
HAVING COUNT(*) > 5;