SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

-- Crear el esquema taskflow si no existe
CREATE SCHEMA IF NOT EXISTS taskflow;

-- Crear tipos ENUM
CREATE TYPE taskflow.tipo_alerta_enum AS ENUM ('DEADLINE', 'PENDING_TASKS', 'TEAM_UPDATE', 'NEW_TASK');
CREATE TYPE taskflow.estado_proyecto_enum AS ENUM ('ACTIVO', 'INACTIVO', 'COMPLETADO', 'CANCELADO');
CREATE TYPE taskflow.estado_usuario_enum AS ENUM ('ACTIVO', 'INACTIVO', 'SUSPENDIDO');
CREATE TYPE taskflow.prioridad_tarea_enum AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'URGENT');
CREATE TYPE taskflow.estado_tarea_enum AS ENUM ('PENDING', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED');

-- Crear extensión para búsqueda de texto
CREATE EXTENSION IF NOT EXISTS pg_trgm SCHEMA taskflow;

-- Crear función para actualizar timestamp
CREATE OR REPLACE FUNCTION taskflow.set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.fecha_actualizacion = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

SET default_tablespace = '';
SET default_table_access_method = heap;

--
-- Name: roles; Type: TABLE; Schema: taskflow;
--

CREATE TABLE taskflow.roles (
    id_rol bigint NOT NULL,
    nombre character varying(50) NOT NULL,
    descripcion text,
    fecha_creacion timestamp without time zone DEFAULT now() NOT NULL,
    fecha_actualizacion timestamp without time zone DEFAULT now() NOT NULL
);

CREATE SEQUENCE taskflow.roles_id_rol_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE taskflow.roles ALTER COLUMN id_rol SET DEFAULT nextval('taskflow.roles_id_rol_seq'::regclass);

--
-- Name: equipos; Type: TABLE; Schema: taskflow;
--

CREATE TABLE taskflow.equipos (
    id_equipo bigint NOT NULL,
    nombre character varying(100) NOT NULL,
    descripcion text,
    color_tag character varying(20),
    fecha_creacion timestamp without time zone DEFAULT now() NOT NULL,
    fecha_actualizacion timestamp without time zone DEFAULT now() NOT NULL
);

CREATE SEQUENCE taskflow.equipos_id_equipo_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE taskflow.equipos ALTER COLUMN id_equipo SET DEFAULT nextval('taskflow.equipos_id_equipo_seq'::regclass);

--
-- Name: usuarios; Type: TABLE; Schema: taskflow;
--

CREATE TABLE taskflow.usuarios (
    id_usuario bigint NOT NULL,
    nombre character varying(100) NOT NULL,
    correo character varying(150) NOT NULL,
    clave_hash character varying(255) NOT NULL,
    id_rol bigint,
    estado taskflow.estado_usuario_enum DEFAULT 'ACTIVO'::taskflow.estado_usuario_enum NOT NULL,
    ultimo_acceso timestamp without time zone,
    fecha_registro timestamp without time zone DEFAULT now() NOT NULL,
    fecha_actualizacion timestamp without time zone DEFAULT now() NOT NULL,
    ruta_imagen character varying(255),
    CONSTRAINT ck_usuarios_correo_valido CHECK ((POSITION(('@'::text) IN (correo)) > 1))
);

CREATE SEQUENCE taskflow.usuarios_id_usuario_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE taskflow.usuarios ALTER COLUMN id_usuario SET DEFAULT nextval('taskflow.usuarios_id_usuario_seq'::regclass);

--
-- Name: usuario_equipo; Type: TABLE; Schema: taskflow;
--

CREATE TABLE taskflow.usuario_equipo (
    id_usuario bigint NOT NULL,
    id_equipo bigint NOT NULL,
    rol_en_equipo character varying(50),
    fecha_creacion timestamp without time zone DEFAULT now() NOT NULL
);

--
-- Name: proyectos; Type: TABLE; Schema: taskflow;
--

CREATE TABLE taskflow.proyectos (
    id_proyecto bigint NOT NULL,
    nombre character varying(150) NOT NULL,
    codigo character varying(50),
    descripcion text,
    id_equipo bigint,
    estado taskflow.estado_proyecto_enum DEFAULT 'ACTIVO'::taskflow.estado_proyecto_enum NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT now() NOT NULL,
    fecha_actualizacion timestamp without time zone DEFAULT now() NOT NULL
);

CREATE SEQUENCE taskflow.proyectos_id_proyecto_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE taskflow.proyectos ALTER COLUMN id_proyecto SET DEFAULT nextval('taskflow.proyectos_id_proyecto_seq'::regclass);

--
-- Name: tareas; Type: TABLE; Schema: taskflow; Owner: postgres
--

CREATE TABLE taskflow.tareas (
    id_tarea bigint NOT NULL,
    id_proyecto bigint,
    titulo character varying(150) NOT NULL,
    descripcion text,
    prioridad taskflow.prioridad_tarea_enum DEFAULT 'MEDIUM'::taskflow.prioridad_tarea_enum NOT NULL,
    estado taskflow.estado_tarea_enum DEFAULT 'PENDING'::taskflow.estado_tarea_enum NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT now() NOT NULL,
    fecha_actualizacion timestamp without time zone DEFAULT now() NOT NULL,
    fecha_limite timestamp without time zone,
    fecha_completada timestamp without time zone,
    creado_por bigint NOT NULL,
    archivado boolean DEFAULT false NOT NULL,
    eliminado boolean DEFAULT false NOT NULL
);

CREATE SEQUENCE taskflow.tareas_id_tarea_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE taskflow.tareas ALTER COLUMN id_tarea SET DEFAULT nextval('taskflow.tareas_id_tarea_seq'::regclass);

--
-- Name: tarea_asignacion; Type: TABLE; Schema: taskflow; Owner: postgres
--

CREATE TABLE taskflow.tarea_asignacion (
    id_tarea bigint NOT NULL,
    id_usuario bigint NOT NULL,
    es_responsable_principal boolean DEFAULT false NOT NULL,
    fecha_asignacion timestamp without time zone DEFAULT now() NOT NULL
);

--
-- Name: archivos_adjuntos; Type: TABLE; Schema: taskflow;
--

CREATE TABLE taskflow.archivos_adjuntos (
    id_archivo bigint NOT NULL,
    id_tarea bigint NOT NULL,
    nombre_archivo character varying(255) NOT NULL,
    ruta_archivo character varying(500) NOT NULL,
    tipo_mime character varying(100),
    es_imagen boolean DEFAULT false NOT NULL,
    subido_por bigint,
    fecha_subida timestamp without time zone DEFAULT now() NOT NULL
);

CREATE SEQUENCE taskflow.archivos_adjuntos_id_archivo_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE taskflow.archivos_adjuntos ALTER COLUMN id_archivo SET DEFAULT nextval('taskflow.archivos_adjuntos_id_archivo_seq'::regclass);

--
-- Name: comentarios_tarea; Type: TABLE; Schema: taskflow; Owner: postgres
--

CREATE TABLE taskflow.comentarios_tarea (
    id_comentario bigint NOT NULL,
    id_tarea bigint NOT NULL,
    id_usuario bigint NOT NULL,
    contenido text NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT now() NOT NULL
);

CREATE SEQUENCE taskflow.comentarios_tarea_id_comentario_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE taskflow.comentarios_tarea ALTER COLUMN id_comentario SET DEFAULT nextval('taskflow.comentarios_tarea_id_comentario_seq'::regclass);

--
-- Name: configuracion_notificaciones; Type: TABLE; Schema: taskflow;
--

CREATE TABLE taskflow.configuracion_notificaciones (
    id_config bigint NOT NULL,
    id_usuario bigint NOT NULL,
    email_activado boolean DEFAULT true NOT NULL,
    alerta_nueva_tarea boolean DEFAULT true NOT NULL,
    alerta_comentario_tarea boolean DEFAULT true NOT NULL,
    alerta_cambio_estado_tarea boolean DEFAULT true NOT NULL,
    recordatorio_vencimiento_activo boolean DEFAULT true NOT NULL,
    minutos_antes_vencimiento integer DEFAULT 60 NOT NULL,
    fecha_creacion timestamp without time zone DEFAULT now() NOT NULL,
    fecha_actualizacion timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT ck_minutos_vencimiento CHECK ((minutos_antes_vencimiento >= 0))
);

CREATE SEQUENCE taskflow.configuracion_notificaciones_id_config_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE taskflow.configuracion_notificaciones ALTER COLUMN id_config SET DEFAULT nextval('taskflow.configuracion_notificaciones_id_config_seq'::regclass);

--
-- Name: alertas; Type: TABLE; Schema: taskflow;
--

CREATE TABLE taskflow.alertas (
    id_alerta bigint NOT NULL,
    id_tarea bigint,
    id_usuario bigint NOT NULL,
    fecha_alerta timestamp without time zone,
    tipo_alerta taskflow.tipo_alerta_enum NOT NULL,
    enviada boolean DEFAULT false NOT NULL,
    fecha_envio timestamp without time zone,
    mensaje text,
    leida boolean DEFAULT false,
    fecha_creacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);

CREATE SEQUENCE taskflow.alertas_id_alerta_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE taskflow.alertas ALTER COLUMN id_alerta SET DEFAULT nextval('taskflow.alertas_id_alerta_seq'::regclass);

--
-- Name: miembros_equipo; Type: TABLE; Schema: taskflow;
--

CREATE TABLE taskflow.miembros_equipo (
    id_equipo bigint NOT NULL,
    id_usuario bigint NOT NULL,
    fecha_union timestamp without time zone DEFAULT now()
);

--
-- PRIMARY KEYS
--

ALTER TABLE ONLY taskflow.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id_rol);

ALTER TABLE ONLY taskflow.roles
    ADD CONSTRAINT roles_nombre_key UNIQUE (nombre);

ALTER TABLE ONLY taskflow.equipos
    ADD CONSTRAINT equipos_pkey PRIMARY KEY (id_equipo);

ALTER TABLE ONLY taskflow.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id_usuario);

ALTER TABLE ONLY taskflow.usuarios
    ADD CONSTRAINT usuarios_correo_key UNIQUE (correo);

ALTER TABLE ONLY taskflow.usuario_equipo
    ADD CONSTRAINT usuario_equipo_pkey PRIMARY KEY (id_usuario, id_equipo);

ALTER TABLE ONLY taskflow.proyectos
    ADD CONSTRAINT proyectos_pkey PRIMARY KEY (id_proyecto);

ALTER TABLE ONLY taskflow.tareas
    ADD CONSTRAINT tareas_pkey PRIMARY KEY (id_tarea);

ALTER TABLE ONLY taskflow.tarea_asignacion
    ADD CONSTRAINT tarea_asignacion_pkey PRIMARY KEY (id_tarea, id_usuario);

ALTER TABLE ONLY taskflow.archivos_adjuntos
    ADD CONSTRAINT archivos_adjuntos_pkey PRIMARY KEY (id_archivo);

ALTER TABLE ONLY taskflow.comentarios_tarea
    ADD CONSTRAINT comentarios_tarea_pkey PRIMARY KEY (id_comentario);

ALTER TABLE ONLY taskflow.configuracion_notificaciones
    ADD CONSTRAINT configuracion_notificaciones_pkey PRIMARY KEY (id_config);

ALTER TABLE ONLY taskflow.configuracion_notificaciones
    ADD CONSTRAINT configuracion_notificaciones_id_usuario_key UNIQUE (id_usuario);

ALTER TABLE ONLY taskflow.alertas
    ADD CONSTRAINT alertas_pkey PRIMARY KEY (id_alerta);

ALTER TABLE ONLY taskflow.miembros_equipo
    ADD CONSTRAINT miembros_equipo_pkey PRIMARY KEY (id_equipo, id_usuario);

--
-- INDEXES
--

CREATE UNIQUE INDEX uq_equipos_nombre ON taskflow.equipos USING btree (lower((nombre)::text));

CREATE INDEX idx_usuarios_nombre_trgm ON taskflow.usuarios USING gin (lower((nombre)::text) taskflow.gin_trgm_ops);
CREATE INDEX idx_usuarios_correo_trgm ON taskflow.usuarios USING gin (lower((correo)::text) taskflow.gin_trgm_ops);

CREATE UNIQUE INDEX uq_proyectos_codigo ON taskflow.proyectos USING btree (codigo);
CREATE INDEX idx_proyectos_equipo_estado ON taskflow.proyectos USING btree (id_equipo, estado);

CREATE INDEX idx_tareas_estado ON taskflow.tareas USING btree (estado);
CREATE INDEX idx_tareas_fecha_limite ON taskflow.tareas USING btree (fecha_limite);
CREATE INDEX idx_tareas_creado_por ON taskflow.tareas USING btree (creado_por);
CREATE INDEX idx_tareas_proyecto ON taskflow.tareas USING btree (id_proyecto);

CREATE UNIQUE INDEX uq_tarea_responsable_principal ON taskflow.tarea_asignacion USING btree (id_tarea) WHERE es_responsable_principal;

CREATE INDEX idx_adjuntos_tarea ON taskflow.archivos_adjuntos USING btree (id_tarea);

CREATE INDEX idx_comentarios_tarea ON taskflow.comentarios_tarea USING btree (id_tarea, fecha_creacion);

CREATE INDEX idx_alertas_usuario_fecha ON taskflow.alertas USING btree (id_usuario, fecha_alerta, enviada);

--
-- FOREIGN KEYS
--

ALTER TABLE ONLY taskflow.usuarios
    ADD CONSTRAINT usuarios_id_rol_fkey FOREIGN KEY (id_rol) REFERENCES taskflow.roles(id_rol);

ALTER TABLE ONLY taskflow.usuario_equipo
    ADD CONSTRAINT usuario_equipo_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES taskflow.usuarios(id_usuario) ON DELETE CASCADE;

ALTER TABLE ONLY taskflow.usuario_equipo
    ADD CONSTRAINT usuario_equipo_id_equipo_fkey FOREIGN KEY (id_equipo) REFERENCES taskflow.equipos(id_equipo) ON DELETE CASCADE;

ALTER TABLE ONLY taskflow.proyectos
    ADD CONSTRAINT proyectos_id_equipo_fkey FOREIGN KEY (id_equipo) REFERENCES taskflow.equipos(id_equipo) ON DELETE SET NULL;

ALTER TABLE ONLY taskflow.tareas
    ADD CONSTRAINT tareas_id_proyecto_fkey FOREIGN KEY (id_proyecto) REFERENCES taskflow.proyectos(id_proyecto) ON DELETE SET NULL;

ALTER TABLE ONLY taskflow.tareas
    ADD CONSTRAINT tareas_creado_por_fkey FOREIGN KEY (creado_por) REFERENCES taskflow.usuarios(id_usuario);

ALTER TABLE ONLY taskflow.tarea_asignacion
    ADD CONSTRAINT tarea_asignacion_id_tarea_fkey FOREIGN KEY (id_tarea) REFERENCES taskflow.tareas(id_tarea) ON DELETE CASCADE;

ALTER TABLE ONLY taskflow.tarea_asignacion
    ADD CONSTRAINT tarea_asignacion_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES taskflow.usuarios(id_usuario) ON DELETE CASCADE;

ALTER TABLE ONLY taskflow.archivos_adjuntos
    ADD CONSTRAINT archivos_adjuntos_id_tarea_fkey FOREIGN KEY (id_tarea) REFERENCES taskflow.tareas(id_tarea) ON DELETE CASCADE;

ALTER TABLE ONLY taskflow.archivos_adjuntos
    ADD CONSTRAINT archivos_adjuntos_subido_por_fkey FOREIGN KEY (subido_por) REFERENCES taskflow.usuarios(id_usuario);

ALTER TABLE ONLY taskflow.comentarios_tarea
    ADD CONSTRAINT comentarios_tarea_id_tarea_fkey FOREIGN KEY (id_tarea) REFERENCES taskflow.tareas(id_tarea) ON DELETE CASCADE;

ALTER TABLE ONLY taskflow.comentarios_tarea
    ADD CONSTRAINT comentarios_tarea_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES taskflow.usuarios(id_usuario) ON DELETE CASCADE;

ALTER TABLE ONLY taskflow.configuracion_notificaciones
    ADD CONSTRAINT configuracion_notificaciones_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES taskflow.usuarios(id_usuario) ON DELETE CASCADE;

ALTER TABLE ONLY taskflow.alertas
    ADD CONSTRAINT alertas_id_tarea_fkey FOREIGN KEY (id_tarea) REFERENCES taskflow.tareas(id_tarea) ON DELETE CASCADE;

ALTER TABLE ONLY taskflow.alertas
    ADD CONSTRAINT alertas_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES taskflow.usuarios(id_usuario) ON DELETE CASCADE;

ALTER TABLE ONLY taskflow.miembros_equipo
    ADD CONSTRAINT miembros_equipo_id_equipo_fkey FOREIGN KEY (id_equipo) REFERENCES taskflow.equipos(id_equipo);

ALTER TABLE ONLY taskflow.miembros_equipo
    ADD CONSTRAINT miembros_equipo_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES taskflow.usuarios(id_usuario);

--
-- TRIGGERS
--

CREATE TRIGGER trg_roles_set_timestamp BEFORE UPDATE ON taskflow.roles FOR EACH ROW EXECUTE FUNCTION taskflow.set_timestamp();

CREATE TRIGGER trg_equipos_set_timestamp BEFORE UPDATE ON taskflow.equipos FOR EACH ROW EXECUTE FUNCTION taskflow.set_timestamp();

CREATE TRIGGER trg_usuarios_set_timestamp BEFORE UPDATE ON taskflow.usuarios FOR EACH ROW EXECUTE FUNCTION taskflow.set_timestamp();

CREATE TRIGGER trg_proyectos_set_timestamp BEFORE UPDATE ON taskflow.proyectos FOR EACH ROW EXECUTE FUNCTION taskflow.set_timestamp();

CREATE TRIGGER trg_tareas_set_timestamp BEFORE UPDATE ON taskflow.tareas FOR EACH ROW EXECUTE FUNCTION taskflow.set_timestamp();

CREATE TRIGGER trg_conf_notif_set_timestamp BEFORE UPDATE ON taskflow.configuracion_notificaciones FOR EACH ROW EXECUTE FUNCTION taskflow.set_timestamp();
