--- ========== ТАБЛИЦЫ ==========

-- 1. Информация о пользователях
create table if not exists users
(
    id                    uuid                     default gen_random_uuid() not null
        primary key,
    email                 text                                               not null,
    phone_number          text,
    username              text                                               not null,
    first_name            text,
    last_name             text,
    gender                text                                               not null
        constraint users_gender_check
            check ((gender = 'MALE'::text) OR (gender = 'FEMALE'::text)),
    email_verified        boolean                  default false             not null,
    phone_number_verified boolean                  default false             not null,
    birthdate             date,
    enabled               boolean                  default true              not null,
    avatar_url            text,
    deleted_at            timestamp with time zone,
    created_at            timestamp with time zone default now()             not null,
    updated_at            timestamp with time zone default now()             not null
);

create unique index users_username_idx
    on users (username);

create unique index users_email_idx
    on users (email);

create unique index users_phone_number_idx
    on users (phone_number)
    where (phone_number IS NOT NULL);

-- 2. Секретные данные пользователей
create table if not exists credentials
(
    id          uuid                     default gen_random_uuid() not null
        primary key,
    user_id     uuid                                               not null
        constraint credentials_users_fk
            references users,
    type        text                                               not null
        constraint credentials_type_check
            check ((type = 'PASSWORD'::text) OR (type = 'PASSWORD_RESTORE_TOKEN'::text) OR
                   (type = '2FA_BIND_KEY'::text) OR (type = '2FA_KEY'::text)),
    secret_data text                                               not null,
    salt        text,
    expires_at  timestamp with time zone,
    created_at  timestamp with time zone default now()             not null
);

create unique index credentials_user_id_type_idx
    on credentials (user_id, type);


-- 3. Пользовательские сессии
create table if not exists user_sessions
(
    id          uuid                     default gen_random_uuid() not null
        primary key,
    user_id     uuid                                               not null,
    status      text                                               not null
        constraint user_sessions_status_check
            check ((status = 'LOGGED_IN'::text) OR (status = 'LOGGED_OUT'::text)),
    token       uuid                                               not null,
    remember_me boolean                  default false             not null,
    created_at  timestamp with time zone default now()             not null,
    updated_at  timestamp with time zone default now()             not null
);

create index user_sessions_user_id_idx
    on user_sessions (user_id);

-- 4. Клиентские сессии
create table if not exists client_sessions
(
    id              uuid                     default gen_random_uuid() not null
        primary key,
    user_id         uuid                                               not null
        constraint client_sessions_users_fk
            references users,
    user_session_id uuid                                               not null
        constraint client_sessions_user_sessions_fk
            references user_sessions on delete cascade,
    client_id       text                                               not null
        constraint client_sessions_client_id_check
            check ((client_id = 'MESSENGER'::text) OR (client_id = 'VIDEOS'::text) OR (client_id = 'SHOP'::text)),
    redirect_uri    text                                               not null,
    status          text                                               not null
        constraint client_sessions_status_check
            check ((status = 'LOGGED_IN'::text) OR (status = 'LOGGED_OUT'::text)),
    created_at      timestamp with time zone default now()             not null,
    updated_at      timestamp with time zone default now()             not null
);

create index client_sessions_user_id_idx
    on client_sessions (user_id);

create index client_sessions_user_session_id_idx
    on client_sessions (user_session_id);

-- 5. Записи о запросах подтверждений
create table if not exists confirmations
(
    id           uuid                     default gen_random_uuid() not null
        primary key,
    user_id      uuid                                               not null
        constraint confirmations_users_fk
            references users,
    type         text                                               not null
        constraint confirmations_type_check
            check ((type = 'EMAIL'::text) OR (type = 'PHONE'::text)),
    code         text,
    expires_at   timestamp with time zone,
    confirmed_at timestamp with time zone,
    created_at   timestamp with time zone default now()             not null
);

create index confirmations_type_user_id_idx
    on confirmations (type, user_id);


-- 6.  Связи со внешними провайдерами аутентификации
create table if not exists external_users
(
    id           uuid                     default gen_random_uuid() not null
        primary key,
    user_id      uuid                                               not null
        constraint external_users_users_fk
            references users,
    external_sub text                                               not null,
    provider     text                                               not null
        constraint external_users_provider_check
            check ((provider = 'VK'::text) OR (provider = 'GOOGLE'::text) OR (provider = 'YANDEX'::text)),
    verified     boolean                  default false             not null,
    created_at   timestamp with time zone default now()             not null,
    updated_at   timestamp with time zone default now()             not null
);

create unique index external_users_user_id_provider_idx
    on external_users (user_id, provider);

-- 7. Коды восстановления доступа к учетной записи
create table if not exists recovery_codes
(
    id         uuid                     default gen_random_uuid() not null
        primary key,
    user_id    uuid                                               not null
        constraint recovery_codes_users_fk
            references users,
    secret     text                                               not null,
    created_at timestamp with time zone default now()             not null,
    deleted_at timestamp with time zone
);

create index recovery_codes_user_id_idx
    on recovery_codes (user_id);

-- 8. Даты первого входа пользователя в каждый юнит экосистемы
create table clients_join_data
(
    user_id   uuid                                   not null,
    client_id text                                   not null,
    joined_at timestamp with time zone default now() not null,
    constraint clients_join_data_pk
        primary key (user_id, client_id)
);

-- 9. История изменений профилей пользователей
create table user_data_changes
(
    user_id   uuid                                   not null,
    client_id text                                   not null,
    joined_at timestamp with time zone default now() not null,
    constraint clients_join_data_pk
        primary key (user_id, client_id)
);



--- ========== ФУНКЦИИ И ТРИГГЕРЫ ==========

-- Функция для логирования изменений в таблице user_data_changes
create or replace function log_user_changes()
returns trigger as $$
declare
    col_name text;
    old_val text;
    new_val text;
begin
    -- Для обновлений
    if (tg_op = 'update') then
        -- Перебираем все столбцы таблицы users
        for col_name in
            select column_name
            from information_schema.columns
            where table_name = 'users'
              and column_name not in ('id', 'created_at', 'updated_at', 'deleted_at') -- Исключаем ненужные столбцы
        loop
            -- Получаем старое и новое значение текущего столбца
            execute format('select ($1).%I, ($2).%I', col_name, col_name)
            into old_val, new_val
            using old, new;

            -- Логируем изменения, только если значения различны
            if old_val is distinct from new_val then
                insert into user_data_changes (user_id, field, old_value, new_value)
                values (old.id, col_name, old_val, new_val);
            end if;
        end loop;
    end if;

    return null; -- Возвращаем null, так как это AFTER триггер
end;
$$ language plpgsql;


-- Функция завершения сессий пользователя при его блокировке
create or replace function logout_user_sessions()
returns TRIGGER as $$
begin
    update user_sessions
    set status = 'LOGGED_OUT'
    where user_id = OLD.id and status = 'LOGGED_IN';
    return OLD;
end;
$$ LANGUAGE plpgsql;

-- Триггеры для функций
create trigger trigger_log_user_changes
after update on users
for each row
execute function log_user_changes();

create trigger trigger_logout_user_sessions
after update on users
for each row
when (OLD.enabled = TRUE and NEW.enabled = FALSE)
execute function logout_user_sessions();