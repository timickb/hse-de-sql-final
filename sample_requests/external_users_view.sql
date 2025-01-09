-- 1. Получить отображение "подтвержденный внешний пользователь, насыщенный внутренними данными нашего ID сервиса"
SELECT
    eu.external_sub as external_sub,
    eu.provider as external_provider,
    eu.user_id as user_id,
    u.email as user_email,
    u.username as username,
    u.enabled as user_enabled,
    u.created_at as user_created_at,
    eu.created_at as external_binded_at
FROM external_users eu
JOIN users u ON (u.id = eu.user_id)
WHERE eu.verified;