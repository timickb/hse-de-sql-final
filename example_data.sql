INSERT INTO users (id, email, phone_number, username, first_name, last_name, gender, email_verified, phone_number_verified, birthdate, enabled, avatar_url, created_at, updated_at)
VALUES
    (gen_random_uuid(), 'alice@example.com', '+1234567890', 'alice123', 'Alice', 'Smith', 'FEMALE', TRUE, FALSE, '1990-05-15', TRUE, 'https://example.com/avatar1.jpg', NOW(), NOW()),
    (gen_random_uuid(), 'bob@example.com', '+9876543210', 'bob456', 'Bob', 'Johnson', 'MALE', FALSE, TRUE, '1985-03-22', FALSE, 'https://example.com/avatar2.jpg', NOW(), NOW()),
    (gen_random_uuid(), 'carol@example.com', NULL, 'carol789', 'Carol', 'Williams', 'FEMALE', TRUE, TRUE, '1992-07-19', TRUE, NULL, NOW(), NOW());

INSERT INTO user_sessions (id, user_id, status, token, remember_me, created_at, updated_at)
VALUES
    (gen_random_uuid(), (SELECT id FROM users WHERE username = 'alice123'), 'LOGGED_IN', gen_random_uuid(), TRUE, NOW(), NOW()),
    (gen_random_uuid(), (SELECT id FROM users WHERE username = 'bob456'), 'LOGGED_OUT', gen_random_uuid(), FALSE, NOW(), NOW()),
    (gen_random_uuid(), (SELECT id FROM users WHERE username = 'carol789'), 'LOGGED_IN', gen_random_uuid(), FALSE, NOW(), NOW());

INSERT INTO client_sessions (id, user_id, user_session_id, client_id, redirect_uri, status, created_at, updated_at)
VALUES
    (gen_random_uuid(), (SELECT id FROM users WHERE username = 'alice123'), (SELECT id FROM user_sessions WHERE user_id = (SELECT id FROM users WHERE username = 'alice123') LIMIT 1), 'MESSENGER', 'https://example.com/messenger', 'LOGGED_IN', NOW(), NOW()),
    (gen_random_uuid(), (SELECT id FROM users WHERE username = 'bob456'), (SELECT id FROM user_sessions WHERE user_id = (SELECT id FROM users WHERE username = 'bob456') LIMIT 1), 'VIDEOS', 'https://example.com/videos', 'LOGGED_OUT', NOW(), NOW()),
    (gen_random_uuid(), (SELECT id FROM users WHERE username = 'carol789'), (SELECT id FROM user_sessions WHERE user_id = (SELECT id FROM users WHERE username = 'carol789') LIMIT 1), 'SHOP', 'https://example.com/shop', 'LOGGED_IN', NOW(), NOW());

INSERT INTO clients_join_data (user_id, client_id, joined_at)
VALUES
    ((SELECT id FROM users WHERE username = 'alice123'), 'MESSENGER', NOW()),
    ((SELECT id FROM users WHERE username = 'bob456'), 'VIDEOS', NOW()),
    ((SELECT id FROM users WHERE username = 'carol789'), 'SHOP', NOW());

INSERT INTO credentials (id, user_id, type, secret_data, salt, expires_at, created_at)
VALUES
    (gen_random_uuid(), (SELECT id FROM users WHERE username = 'alice123'), 'PASSWORD', '*****', '***', NULL, NOW()),
    (gen_random_uuid(), (SELECT id FROM users WHERE username = 'alice123'), 'PASSWORD_RESTORE_TOKEN', '*****', NULL, NOW() + INTERVAL '1 day', NOW()),
    (gen_random_uuid(), (SELECT id FROM users WHERE username = 'alice123'), '2FA_BIND_KEY', '*****', NULL, NOW() + INTERVAL '1 day', NOW()),
    (gen_random_uuid(), (SELECT id FROM users WHERE username = 'alice123'), '2FA_KEY', '*****', '***', NULL, NOW());

INSERT INTO external_users (id, user_id, external_sub, provider, verified)
VALUES
    (gen_random_uuid(), (SELECT id FROM users WHERE username = 'bob456'), '12345', 'VK', true),
    (gen_random_uuid(), (SELECT id FROM users WHERE username = 'carol789'), '54321', 'VK', true);