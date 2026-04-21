--
-- PostgreSQL database dump
--

\restrict nrdVTCPzmkuaM10d5nquxPtFVuo55d7oOEXrFXIFUvxO4VQS7efaBPpKtOKPUjj

-- Dumped from database version 17.9 (Debian 17.9-1.pgdg12+1)
-- Dumped by pg_dump version 18.3

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

--
-- Name: vector; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;


--
-- Name: EXTENSION vector; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION vector IS 'vector data type and ivfflat and hnsw access methods';


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: clients; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.clients (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    team_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    email character varying(255),
    phone character varying(50),
    contact_name character varying(120),
    billing_address jsonb,
    tax_id character varying(64),
    notes text,
    default_hourly_rate_cents integer,
    currency character varying(3) DEFAULT 'USD'::character varying NOT NULL,
    archived_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT clients_billing_address_check CHECK (((billing_address IS NULL) OR (jsonb_typeof(billing_address) = 'object'::text))),
    CONSTRAINT clients_default_hourly_rate_cents_check CHECK ((default_hourly_rate_cents >= 0))
);


ALTER TABLE public.clients OWNER TO postgres;

--
-- Name: invites; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.invites (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    team_id uuid NOT NULL,
    email text NOT NULL,
    role text NOT NULL,
    token text NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    accepted_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT invites_role_check CHECK ((role = ANY (ARRAY['ADMIN'::text, 'MEMBER'::text, 'VIEWER'::text, 'BILLING'::text, 'OWNER'::text])))
);


ALTER TABLE public.invites OWNER TO postgres;

--
-- Name: TABLE invites; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.invites IS 'Pending team invitations for users not yet in the system.';


--
-- Name: invoice_items; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.invoice_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    team_id uuid NOT NULL,
    invoice_id uuid NOT NULL,
    time_entry_id uuid,
    description text NOT NULL,
    quantity numeric(10,2) NOT NULL,
    rate_cents integer NOT NULL,
    amount_cents integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.invoice_items OWNER TO postgres;

--
-- Name: invoice_time_entries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.invoice_time_entries (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    invoice_id uuid NOT NULL,
    time_entry_id uuid NOT NULL,
    invoice_item_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.invoice_time_entries OWNER TO postgres;

--
-- Name: TABLE invoice_time_entries; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.invoice_time_entries IS 'Junction table tracking which time entries are included in which invoices. Allows grouping multiple time entries into single invoice line items while tracking invoicing status.';


--
-- Name: COLUMN invoice_time_entries.invoice_item_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.invoice_time_entries.invoice_item_id IS 'Links time entry to the specific invoice line item it belongs to, allowing quantity recalculation when entries are removed';


--
-- Name: invoices; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.invoices (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    team_id uuid NOT NULL,
    client_id uuid NOT NULL,
    invoice_number character varying(50) NOT NULL,
    status character varying(20) DEFAULT 'draft'::character varying NOT NULL,
    issued_date date NOT NULL,
    due_date date NOT NULL,
    subtotal_cents integer DEFAULT 0 NOT NULL,
    tax_rate_percent numeric(5,2) DEFAULT 0 NOT NULL,
    tax_amount_cents integer DEFAULT 0 NOT NULL,
    total_cents integer DEFAULT 0 NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT invoices_status_check CHECK (((status)::text = ANY ((ARRAY['draft'::character varying, 'sent'::character varying, 'paid'::character varying, 'cancelled'::character varying])::text[])))
);


ALTER TABLE public.invoices OWNER TO postgres;

--
-- Name: migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.migrations (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    executed_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.migrations OWNER TO postgres;

--
-- Name: migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.migrations_id_seq OWNER TO postgres;

--
-- Name: migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.migrations_id_seq OWNED BY public.migrations.id;


--
-- Name: project_members; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.project_members (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    team_id uuid NOT NULL,
    project_id uuid NOT NULL,
    user_id uuid NOT NULL,
    role text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT project_members_role_check CHECK ((role = ANY (ARRAY['MANAGER'::text, 'CONTRIBUTOR'::text, 'VIEWER'::text])))
);


ALTER TABLE public.project_members OWNER TO postgres;

--
-- Name: TABLE project_members; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.project_members IS 'Links users to projects with their role (MANAGER/CONTRIBUTOR/VIEWER).';


--
-- Name: COLUMN project_members.role; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.project_members.role IS 'Project-level role: MANAGER (full control), CONTRIBUTOR (can log time), VIEWER (read-only).';


--
-- Name: project_tasks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.project_tasks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    team_id uuid NOT NULL,
    project_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    status text DEFAULT 'active'::text NOT NULL,
    billable boolean DEFAULT true NOT NULL,
    hourly_rate_cents integer,
    tags text[] DEFAULT ARRAY[]::text[] NOT NULL,
    order_index integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT project_tasks_hourly_rate_cents_check CHECK (((hourly_rate_cents IS NULL) OR (hourly_rate_cents >= 0))),
    CONSTRAINT project_tasks_name_check CHECK (((length(name) >= 1) AND (length(name) <= 255))),
    CONSTRAINT project_tasks_status_check CHECK ((status = ANY (ARRAY['active'::text, 'archived'::text, 'completed'::text, 'on_hold'::text])))
);


ALTER TABLE public.project_tasks OWNER TO postgres;

--
-- Name: TABLE project_tasks; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.project_tasks IS 'Tasks within a project with optional task-level hourly rates.';


--
-- Name: COLUMN project_tasks.billable; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.project_tasks.billable IS 'Whether time logged on this task is billable.';


--
-- Name: COLUMN project_tasks.hourly_rate_cents; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.project_tasks.hourly_rate_cents IS 'Task-specific rate; overrides project default if set.';


--
-- Name: projects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projects (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    team_id uuid NOT NULL,
    client_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    code text,
    description text,
    status text DEFAULT 'active'::text NOT NULL,
    color text,
    tags text[] DEFAULT ARRAY[]::text[] NOT NULL,
    default_hourly_rate_cents integer,
    budget_type text,
    budget_hours integer,
    budget_amount_cents integer,
    start_date date,
    due_date date,
    archived_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT projects_budget_amount_cents_check CHECK (((budget_amount_cents IS NULL) OR (budget_amount_cents >= 0))),
    CONSTRAINT projects_budget_hours_check CHECK (((budget_hours IS NULL) OR (budget_hours >= 0))),
    CONSTRAINT projects_budget_type_check CHECK ((budget_type = ANY (ARRAY['none'::text, 'hours'::text, 'amount'::text]))),
    CONSTRAINT projects_default_hourly_rate_cents_check CHECK (((default_hourly_rate_cents IS NULL) OR (default_hourly_rate_cents >= 0))),
    CONSTRAINT projects_status_check CHECK ((status = ANY (ARRAY['active'::text, 'archived'::text, 'completed'::text, 'on_hold'::text])))
);


ALTER TABLE public.projects OWNER TO postgres;

--
-- Name: schema_ardine_short; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.schema_ardine_short (
    id integer NOT NULL,
    table_name character varying(50),
    content text,
    embedding public.vector(768)
);


ALTER TABLE public.schema_ardine_short OWNER TO postgres;

--
-- Name: schema_ardine_short_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.schema_ardine_short_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.schema_ardine_short_id_seq OWNER TO postgres;

--
-- Name: schema_ardine_short_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.schema_ardine_short_id_seq OWNED BY public.schema_ardine_short.id;


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sessions (
    id character varying(255) NOT NULL,
    user_id uuid NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.sessions OWNER TO postgres;

--
-- Name: task_assignees; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.task_assignees (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    team_id uuid NOT NULL,
    task_id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.task_assignees OWNER TO postgres;

--
-- Name: TABLE task_assignees; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.task_assignees IS 'Links users to specific tasks as assignees.';


--
-- Name: team_memberships; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.team_memberships (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    team_id uuid NOT NULL,
    user_id uuid NOT NULL,
    role text NOT NULL,
    invited_at timestamp with time zone,
    joined_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT team_memberships_role_check CHECK ((role = ANY (ARRAY['OWNER'::text, 'ADMIN'::text, 'MEMBER'::text, 'VIEWER'::text, 'BILLING'::text])))
);


ALTER TABLE public.team_memberships OWNER TO postgres;

--
-- Name: TABLE team_memberships; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.team_memberships IS 'Links users to teams with their role (OWNER/ADMIN/MEMBER/VIEWER/BILLING).';


--
-- Name: COLUMN team_memberships.role; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.team_memberships.role IS 'Team-level role: OWNER (full control), ADMIN (manage team), MEMBER (create/edit), VIEWER (read-only), BILLING (manage billing).';


--
-- Name: teams; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.teams (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    slug text NOT NULL,
    billing_address jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT teams_name_check CHECK (((length(name) >= 2) AND (length(name) <= 120))),
    CONSTRAINT teams_slug_check CHECK (((length(slug) >= 2) AND (length(slug) <= 120)))
);


ALTER TABLE public.teams OWNER TO postgres;

--
-- Name: TABLE teams; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.teams IS 'Teams are the primary unit of data organization. All business data is scoped to a team.';


--
-- Name: time_entries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.time_entries (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    team_id uuid NOT NULL,
    project_id uuid NOT NULL,
    task_id uuid,
    user_id uuid,
    client_id uuid,
    note text,
    started_at timestamp with time zone NOT NULL,
    stopped_at timestamp with time zone,
    duration_seconds integer,
    billable boolean DEFAULT true NOT NULL,
    hourly_rate_cents integer,
    amount_cents integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT time_entries_check CHECK (((stopped_at IS NULL) OR (stopped_at > started_at))),
    CONSTRAINT time_entries_hourly_rate_cents_check CHECK (((hourly_rate_cents IS NULL) OR (hourly_rate_cents >= 0)))
);


ALTER TABLE public.time_entries OWNER TO postgres;

--
-- Name: COLUMN time_entries.task_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.time_entries.task_id IS 'Optional task within the project';


--
-- Name: COLUMN time_entries.user_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.time_entries.user_id IS 'User who logged this time entry';


--
-- Name: COLUMN time_entries.client_id; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.time_entries.client_id IS 'Denormalized client_id from project for easier queries';


--
-- Name: COLUMN time_entries.note; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.time_entries.note IS 'Optional description/note about what was worked on';


--
-- Name: COLUMN time_entries.started_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.time_entries.started_at IS 'When the timer started';


--
-- Name: COLUMN time_entries.stopped_at; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.time_entries.stopped_at IS 'When the timer stopped (NULL if running)';


--
-- Name: COLUMN time_entries.duration_seconds; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.time_entries.duration_seconds IS 'Auto-calculated duration in seconds (stopped_at - started_at)';


--
-- Name: COLUMN time_entries.billable; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.time_entries.billable IS 'Whether this time entry is billable to the client';


--
-- Name: COLUMN time_entries.hourly_rate_cents; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.time_entries.hourly_rate_cents IS 'Stored hourly rate in cents at time of entry creation (uses rate resolution)';


--
-- Name: COLUMN time_entries.amount_cents; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.time_entries.amount_cents IS 'Auto-calculated billing amount: (duration_seconds * hourly_rate_cents / 3600)';


--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    instance_role text DEFAULT 'USER'::text NOT NULL,
    display_name character varying(120),
    email_verified_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT users_instance_role_check CHECK ((instance_role = ANY (ARRAY['USER'::text, 'ADMIN'::text])))
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: COLUMN users.instance_role; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.users.instance_role IS 'Instance-level role: ADMIN can manage all teams and users, USER is a regular user.';


--
-- Name: migrations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.migrations ALTER COLUMN id SET DEFAULT nextval('public.migrations_id_seq'::regclass);


--
-- Name: schema_ardine_short id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schema_ardine_short ALTER COLUMN id SET DEFAULT nextval('public.schema_ardine_short_id_seq'::regclass);


--
-- Data for Name: clients; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.clients (id, team_id, name, email, phone, contact_name, billing_address, tax_id, notes, default_hourly_rate_cents, currency, archived_at, created_at, updated_at) FROM stdin;
d1000000-0000-0000-0000-000000000001	a1000000-0000-0000-0000-000000000001	TechStart Thailand	contact@techstart.th	+66-2-100-1000	Somchai Rak	\N	TH-1234567890	Startup client, fast payment, needs weekly updates	15000	USD	\N	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
d1000000-0000-0000-0000-000000000002	a1000000-0000-0000-0000-000000000001	MegaCorp Japan	projects@megacorp.jp	+81-3-9999-8888	Yuki Tanaka	\N	JP-9876543210	Enterprise client, payment NET-30, formal communication required	20000	USD	\N	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
d1000000-0000-0000-0000-000000000003	a1000000-0000-0000-0000-000000000001	OldSchool Corp	it@oldschool.co	+66-2-200-2000	Preecha Jaidee	\N	TH-1111111111	Legacy client, low budget, project on hold	8000	USD	2026-04-10 19:01:28.11178+00	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
d1000000-0000-0000-0000-000000000004	a1000000-0000-0000-0000-000000000002	CloudNine Singapore	dev@cloudnine.sg	+65-6-123-4567	Raj Patel	\N	SG-5555555555	Cloud infrastructure project, long-term contract	25000	SGD	\N	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
d1000000-0000-0000-0000-000000000005	a1000000-0000-0000-0000-000000000002	StartupX Vietnam	hello@startupx.vn	+84-28-1234-5678	Linh Nguyen	\N	\N	New client, trial project first	12000	USD	\N	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
e6f87dda-6cc3-4d0e-b34b-f84a6953053e	6eb9a25a-ec68-464b-a265-0eba6a0f8baa	Worada Sarakhon	65070203@kmitl.ac.th	\N	Worada Sarakhon	{"city": "New York", "state": "NY", "street": "123 fear street", "country": "US", "postalCode": "10001"}	\N	\N	\N	USD	\N	2026-04-21 08:17:22.223279+00	2026-04-21 08:17:22.223279+00
\.


--
-- Data for Name: invites; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.invites (id, team_id, email, role, token, expires_at, accepted_at, created_at) FROM stdin;
d2638749-8eb0-48ad-8a48-3289da5fb9e4	26705c95-f666-4ce8-9116-14387d0705fc	invite@placeholder.com	OWNER	935684199c30893399683c3cd5554eed62a27b72aff5916fd8cab61f9dc98859	2026-04-28 04:13:31.374+00	\N	2026-04-21 04:13:31.375318+00
\.


--
-- Data for Name: invoice_items; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.invoice_items (id, team_id, invoice_id, time_entry_id, description, quantity, rate_cents, amount_cents, created_at) FROM stdin;
e2000000-0000-0000-0000-000000000001	a1000000-0000-0000-0000-000000000001	d2000000-0000-0000-0000-000000000001	c2000000-0000-0000-0000-000000000001	UI/UX Design review	3.00	15000	45000	2026-04-20 19:01:28.11178+00
e2000000-0000-0000-0000-000000000002	a1000000-0000-0000-0000-000000000001	d2000000-0000-0000-0000-000000000001	c2000000-0000-0000-0000-000000000002	Next.js project setup	6.00	15000	90000	2026-04-20 19:01:28.11178+00
e2000000-0000-0000-0000-000000000003	a1000000-0000-0000-0000-000000000001	d2000000-0000-0000-0000-000000000001	c2000000-0000-0000-0000-000000000003	Product listing page	8.00	15000	120000	2026-04-20 19:01:28.11178+00
e2000000-0000-0000-0000-000000000004	a1000000-0000-0000-0000-000000000001	d2000000-0000-0000-0000-000000000001	c2000000-0000-0000-0000-000000000004	Shopping cart and checkout	7.00	15000	105000	2026-04-20 19:01:28.11178+00
e2000000-0000-0000-0000-000000000005	a1000000-0000-0000-0000-000000000001	d2000000-0000-0000-0000-000000000001	c2000000-0000-0000-0000-000000000005	Stripe payment integration	5.00	15000	75000	2026-04-20 19:01:28.11178+00
e2000000-0000-0000-0000-000000000006	a1000000-0000-0000-0000-000000000001	d2000000-0000-0000-0000-000000000002	c2000000-0000-0000-0000-000000000010	Salesforce API design	8.00	20000	160000	2026-04-20 19:01:28.11178+00
e2000000-0000-0000-0000-000000000007	a1000000-0000-0000-0000-000000000001	d2000000-0000-0000-0000-000000000002	c2000000-0000-0000-0000-000000000011	ERP connector development	10.00	20000	200000	2026-04-20 19:01:28.11178+00
e2000000-0000-0000-0000-000000000008	a1000000-0000-0000-0000-000000000001	d2000000-0000-0000-0000-000000000002	c2000000-0000-0000-0000-000000000012	Integration testing	6.00	20000	120000	2026-04-20 19:01:28.11178+00
e2000000-0000-0000-0000-000000000009	a1000000-0000-0000-0000-000000000001	d2000000-0000-0000-0000-000000000003	c2000000-0000-0000-0000-000000000007	App navigation setup	4.00	15000	60000	2026-04-20 19:01:28.11178+00
e2000000-0000-0000-0000-000000000010	a1000000-0000-0000-0000-000000000001	d2000000-0000-0000-0000-000000000003	c2000000-0000-0000-0000-000000000008	JWT authentication	6.00	15000	90000	2026-04-20 19:01:28.11178+00
e2000000-0000-0000-0000-000000000011	a1000000-0000-0000-0000-000000000001	d2000000-0000-0000-0000-000000000003	c2000000-0000-0000-0000-000000000009	Push notifications	5.00	15000	75000	2026-04-20 19:01:28.11178+00
e2000000-0000-0000-0000-000000000012	a1000000-0000-0000-0000-000000000001	d2000000-0000-0000-0000-000000000004	c2000000-0000-0000-0000-000000000013	DB query optimization	7.00	20000	140000	2026-04-20 19:01:28.11178+00
e2000000-0000-0000-0000-000000000013	a1000000-0000-0000-0000-000000000001	d2000000-0000-0000-0000-000000000004	c2000000-0000-0000-0000-000000000014	Chart components	8.00	20000	160000	2026-04-20 19:01:28.11178+00
e2000000-0000-0000-0000-000000000014	a1000000-0000-0000-0000-000000000002	d2000000-0000-0000-0000-000000000005	c2000000-0000-0000-0000-000000000015	Service discovery setup	8.00	25000	200000	2026-04-20 19:01:28.11178+00
e2000000-0000-0000-0000-000000000015	a1000000-0000-0000-0000-000000000002	d2000000-0000-0000-0000-000000000005	c2000000-0000-0000-0000-000000000016	Helm charts (backend)	10.00	25000	250000	2026-04-20 19:01:28.11178+00
e2000000-0000-0000-0000-000000000016	a1000000-0000-0000-0000-000000000002	d2000000-0000-0000-0000-000000000005	c2000000-0000-0000-0000-000000000017	Prometheus + Grafana	9.00	25000	225000	2026-04-20 19:01:28.11178+00
e2000000-0000-0000-0000-000000000017	a1000000-0000-0000-0000-000000000002	d2000000-0000-0000-0000-000000000006	c2000000-0000-0000-0000-000000000018	Helm charts (frontend)	8.00	25000	200000	2026-04-20 19:01:28.11178+00
e2000000-0000-0000-0000-000000000018	a1000000-0000-0000-0000-000000000002	d2000000-0000-0000-0000-000000000006	\N	CI/CD pipeline documentation	9.00	25000	225000	2026-04-20 19:01:28.11178+00
\.


--
-- Data for Name: invoice_time_entries; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.invoice_time_entries (id, invoice_id, time_entry_id, invoice_item_id, created_at) FROM stdin;
f2000000-0000-0000-0000-000000000001	d2000000-0000-0000-0000-000000000001	c2000000-0000-0000-0000-000000000001	e2000000-0000-0000-0000-000000000001	2026-04-20 19:01:28.11178+00
f2000000-0000-0000-0000-000000000002	d2000000-0000-0000-0000-000000000001	c2000000-0000-0000-0000-000000000002	e2000000-0000-0000-0000-000000000002	2026-04-20 19:01:28.11178+00
f2000000-0000-0000-0000-000000000003	d2000000-0000-0000-0000-000000000001	c2000000-0000-0000-0000-000000000003	e2000000-0000-0000-0000-000000000003	2026-04-20 19:01:28.11178+00
f2000000-0000-0000-0000-000000000004	d2000000-0000-0000-0000-000000000001	c2000000-0000-0000-0000-000000000004	e2000000-0000-0000-0000-000000000004	2026-04-20 19:01:28.11178+00
f2000000-0000-0000-0000-000000000005	d2000000-0000-0000-0000-000000000001	c2000000-0000-0000-0000-000000000005	e2000000-0000-0000-0000-000000000005	2026-04-20 19:01:28.11178+00
f2000000-0000-0000-0000-000000000006	d2000000-0000-0000-0000-000000000002	c2000000-0000-0000-0000-000000000010	e2000000-0000-0000-0000-000000000006	2026-04-20 19:01:28.11178+00
f2000000-0000-0000-0000-000000000007	d2000000-0000-0000-0000-000000000002	c2000000-0000-0000-0000-000000000011	e2000000-0000-0000-0000-000000000007	2026-04-20 19:01:28.11178+00
f2000000-0000-0000-0000-000000000008	d2000000-0000-0000-0000-000000000002	c2000000-0000-0000-0000-000000000012	e2000000-0000-0000-0000-000000000008	2026-04-20 19:01:28.11178+00
f2000000-0000-0000-0000-000000000009	d2000000-0000-0000-0000-000000000003	c2000000-0000-0000-0000-000000000007	e2000000-0000-0000-0000-000000000009	2026-04-20 19:01:28.11178+00
f2000000-0000-0000-0000-000000000010	d2000000-0000-0000-0000-000000000003	c2000000-0000-0000-0000-000000000008	e2000000-0000-0000-0000-000000000010	2026-04-20 19:01:28.11178+00
f2000000-0000-0000-0000-000000000011	d2000000-0000-0000-0000-000000000003	c2000000-0000-0000-0000-000000000009	e2000000-0000-0000-0000-000000000011	2026-04-20 19:01:28.11178+00
f2000000-0000-0000-0000-000000000012	d2000000-0000-0000-0000-000000000004	c2000000-0000-0000-0000-000000000013	e2000000-0000-0000-0000-000000000012	2026-04-20 19:01:28.11178+00
f2000000-0000-0000-0000-000000000013	d2000000-0000-0000-0000-000000000004	c2000000-0000-0000-0000-000000000014	e2000000-0000-0000-0000-000000000013	2026-04-20 19:01:28.11178+00
f2000000-0000-0000-0000-000000000014	d2000000-0000-0000-0000-000000000005	c2000000-0000-0000-0000-000000000015	e2000000-0000-0000-0000-000000000014	2026-04-20 19:01:28.11178+00
f2000000-0000-0000-0000-000000000015	d2000000-0000-0000-0000-000000000005	c2000000-0000-0000-0000-000000000016	e2000000-0000-0000-0000-000000000015	2026-04-20 19:01:28.11178+00
f2000000-0000-0000-0000-000000000016	d2000000-0000-0000-0000-000000000005	c2000000-0000-0000-0000-000000000017	e2000000-0000-0000-0000-000000000016	2026-04-20 19:01:28.11178+00
f2000000-0000-0000-0000-000000000017	d2000000-0000-0000-0000-000000000006	c2000000-0000-0000-0000-000000000018	e2000000-0000-0000-0000-000000000017	2026-04-20 19:01:28.11178+00
\.


--
-- Data for Name: invoices; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.invoices (id, team_id, client_id, invoice_number, status, issued_date, due_date, subtotal_cents, tax_rate_percent, tax_amount_cents, total_cents, notes, created_at, updated_at) FROM stdin;
d2000000-0000-0000-0000-000000000001	a1000000-0000-0000-0000-000000000001	d1000000-0000-0000-0000-000000000001	INV-2025-001	paid	2025-02-01	2025-02-28	435000	7.00	30450	465450	February billing for E-Commerce Platform work	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
d2000000-0000-0000-0000-000000000002	a1000000-0000-0000-0000-000000000001	d1000000-0000-0000-0000-000000000002	INV-2025-002	paid	2025-02-15	2025-03-15	480000	0.00	0	480000	Final billing for Enterprise CRM Integration project	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
d2000000-0000-0000-0000-000000000003	a1000000-0000-0000-0000-000000000001	d1000000-0000-0000-0000-000000000001	INV-2025-003	sent	2025-03-01	2025-03-31	225000	7.00	15750	240750	March billing for Mobile App MVP	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
d2000000-0000-0000-0000-000000000004	a1000000-0000-0000-0000-000000000001	d1000000-0000-0000-0000-000000000002	INV-2025-004	draft	2025-04-01	2025-04-30	300000	0.00	0	300000	April billing for Analytics Dashboard	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
d2000000-0000-0000-0000-000000000005	a1000000-0000-0000-0000-000000000002	d1000000-0000-0000-0000-000000000004	INV-2025-005	paid	2025-03-01	2025-03-31	675000	9.00	60750	735750	March billing for Kubernetes Migration	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
d2000000-0000-0000-0000-000000000006	a1000000-0000-0000-0000-000000000002	d1000000-0000-0000-0000-000000000004	INV-2025-006	sent	2025-03-15	2025-04-14	425000	9.00	38250	463250	CI/CD Pipeline final invoice — OVERDUE	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
\.


--
-- Data for Name: migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.migrations (id, name, executed_at) FROM stdin;
\.


--
-- Data for Name: project_members; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.project_members (id, team_id, project_id, user_id, role, created_at, updated_at) FROM stdin;
f1000000-0000-0000-0000-000000000001	a1000000-0000-0000-0000-000000000001	e1000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000001	MANAGER	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
f1000000-0000-0000-0000-000000000002	a1000000-0000-0000-0000-000000000001	e1000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	CONTRIBUTOR	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
f1000000-0000-0000-0000-000000000003	a1000000-0000-0000-0000-000000000001	e1000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000006	CONTRIBUTOR	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
f1000000-0000-0000-0000-000000000004	a1000000-0000-0000-0000-000000000001	e1000000-0000-0000-0000-000000000002	b1000000-0000-0000-0000-000000000001	MANAGER	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
f1000000-0000-0000-0000-000000000005	a1000000-0000-0000-0000-000000000001	e1000000-0000-0000-0000-000000000002	b1000000-0000-0000-0000-000000000003	CONTRIBUTOR	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
f1000000-0000-0000-0000-000000000006	a1000000-0000-0000-0000-000000000001	e1000000-0000-0000-0000-000000000003	b1000000-0000-0000-0000-000000000002	MANAGER	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
f1000000-0000-0000-0000-000000000007	a1000000-0000-0000-0000-000000000001	e1000000-0000-0000-0000-000000000003	b1000000-0000-0000-0000-000000000003	CONTRIBUTOR	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
f1000000-0000-0000-0000-000000000008	a1000000-0000-0000-0000-000000000001	e1000000-0000-0000-0000-000000000004	b1000000-0000-0000-0000-000000000002	MANAGER	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
f1000000-0000-0000-0000-000000000009	a1000000-0000-0000-0000-000000000001	e1000000-0000-0000-0000-000000000004	b1000000-0000-0000-0000-000000000006	CONTRIBUTOR	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
f1000000-0000-0000-0000-000000000010	a1000000-0000-0000-0000-000000000002	e1000000-0000-0000-0000-000000000006	b1000000-0000-0000-0000-000000000004	MANAGER	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
f1000000-0000-0000-0000-000000000011	a1000000-0000-0000-0000-000000000002	e1000000-0000-0000-0000-000000000006	b1000000-0000-0000-0000-000000000005	CONTRIBUTOR	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
f1000000-0000-0000-0000-000000000012	a1000000-0000-0000-0000-000000000002	e1000000-0000-0000-0000-000000000008	b1000000-0000-0000-0000-000000000004	MANAGER	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
f1000000-0000-0000-0000-000000000013	a1000000-0000-0000-0000-000000000002	e1000000-0000-0000-0000-000000000008	b1000000-0000-0000-0000-000000000005	CONTRIBUTOR	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
\.


--
-- Data for Name: project_tasks; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.project_tasks (id, team_id, project_id, name, description, status, billable, hourly_rate_cents, tags, order_index, created_at, updated_at) FROM stdin;
a2000000-0000-0000-0000-000000000001	a1000000-0000-0000-0000-000000000001	e1000000-0000-0000-0000-000000000001	UI/UX Design	Figma wireframes and design system	completed	t	15000	{}	1	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
a2000000-0000-0000-0000-000000000002	a1000000-0000-0000-0000-000000000001	e1000000-0000-0000-0000-000000000001	Frontend Development	Next.js implementation	active	t	15000	{}	2	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
a2000000-0000-0000-0000-000000000003	a1000000-0000-0000-0000-000000000001	e1000000-0000-0000-0000-000000000001	API Integration	Connect to payment gateway	active	t	15000	{}	3	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
a2000000-0000-0000-0000-000000000004	a1000000-0000-0000-0000-000000000001	e1000000-0000-0000-0000-000000000001	Internal Meeting	Team sync and planning	active	f	\N	{}	4	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
a2000000-0000-0000-0000-000000000005	a1000000-0000-0000-0000-000000000001	e1000000-0000-0000-0000-000000000002	App Architecture	Setup navigation and state management	completed	t	15000	{}	1	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
a2000000-0000-0000-0000-000000000006	a1000000-0000-0000-0000-000000000001	e1000000-0000-0000-0000-000000000002	Authentication Module	Login, register, OAuth	active	t	15000	{}	2	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
a2000000-0000-0000-0000-000000000007	a1000000-0000-0000-0000-000000000001	e1000000-0000-0000-0000-000000000002	Push Notifications	Firebase Cloud Messaging	active	t	15000	{}	3	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
a2000000-0000-0000-0000-000000000008	a1000000-0000-0000-0000-000000000001	e1000000-0000-0000-0000-000000000004	Data Pipeline	ETL from multiple sources	active	t	20000	{}	1	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
a2000000-0000-0000-0000-000000000009	a1000000-0000-0000-0000-000000000001	e1000000-0000-0000-0000-000000000004	Chart Components	D3.js interactive charts	active	t	20000	{}	2	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
a2000000-0000-0000-0000-000000000010	a1000000-0000-0000-0000-000000000002	e1000000-0000-0000-0000-000000000006	Service Discovery Setup	Configure CoreDNS and services	completed	t	25000	{}	1	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
a2000000-0000-0000-0000-000000000011	a1000000-0000-0000-0000-000000000002	e1000000-0000-0000-0000-000000000006	Helm Charts	Write Helm charts for all services	active	t	25000	{}	2	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
a2000000-0000-0000-0000-000000000012	a1000000-0000-0000-0000-000000000002	e1000000-0000-0000-0000-000000000006	Monitoring Stack	Prometheus + Grafana setup	active	t	25000	{}	3	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
a2000000-0000-0000-0000-000000000013	a1000000-0000-0000-0000-000000000002	e1000000-0000-0000-0000-000000000008	Security Scan	Run vulnerability assessment	active	t	12000	{}	1	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
a2000000-0000-0000-0000-000000000014	a1000000-0000-0000-0000-000000000002	e1000000-0000-0000-0000-000000000008	Report Writing	Document findings and recommendations	active	f	\N	{}	2	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
\.


--
-- Data for Name: projects; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.projects (id, team_id, client_id, name, code, description, status, color, tags, default_hourly_rate_cents, budget_type, budget_hours, budget_amount_cents, start_date, due_date, archived_at, created_at, updated_at) FROM stdin;
e1000000-0000-0000-0000-000000000001	a1000000-0000-0000-0000-000000000001	d1000000-0000-0000-0000-000000000001	E-Commerce Platform Redesign	TECH-001	Full redesign of their e-commerce website using Next.js	active	#FF6B6B	{frontend,nextjs,urgent}	15000	hours	200	\N	2025-01-01	2025-06-30	\N	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
e1000000-0000-0000-0000-000000000002	a1000000-0000-0000-0000-000000000001	d1000000-0000-0000-0000-000000000001	Mobile App MVP	TECH-002	React Native app for iOS and Android	active	#4ECDC4	{mobile,react-native}	15000	amount	\N	3000000	2025-03-01	2025-09-30	\N	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
e1000000-0000-0000-0000-000000000003	a1000000-0000-0000-0000-000000000001	d1000000-0000-0000-0000-000000000002	Enterprise CRM Integration	MEGA-001	Integrate Salesforce with their internal ERP system	completed	#45B7D1	{backend,integration,salesforce}	20000	amount	\N	5000000	2024-09-01	2025-01-31	\N	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
e1000000-0000-0000-0000-000000000004	a1000000-0000-0000-0000-000000000001	d1000000-0000-0000-0000-000000000002	Data Analytics Dashboard	MEGA-002	Real-time analytics dashboard with D3.js and PostgreSQL	active	#96CEB4	{frontend,data,analytics}	20000	hours	150	\N	2025-02-01	2025-07-31	\N	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
e1000000-0000-0000-0000-000000000005	a1000000-0000-0000-0000-000000000001	d1000000-0000-0000-0000-000000000003	Legacy System Migration	OLD-001	Migrate from PHP 5.6 to modern stack	on_hold	#DDA0DD	{backend,legacy}	8000	none	\N	\N	2025-01-15	\N	\N	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
e1000000-0000-0000-0000-000000000006	a1000000-0000-0000-0000-000000000002	d1000000-0000-0000-0000-000000000004	Kubernetes Migration	CLOUD-001	Migrate 50+ microservices to Kubernetes on AWS EKS	active	#FF8C00	{devops,kubernetes,aws}	25000	hours	500	\N	2025-01-15	2025-12-31	\N	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
e1000000-0000-0000-0000-000000000007	a1000000-0000-0000-0000-000000000002	d1000000-0000-0000-0000-000000000004	CI/CD Pipeline Setup	CLOUD-002	Setup GitHub Actions + ArgoCD pipeline	completed	#98D8C8	{devops,ci-cd,github-actions}	25000	amount	\N	750000	2024-11-01	2025-01-15	\N	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
e1000000-0000-0000-0000-000000000008	a1000000-0000-0000-0000-000000000002	d1000000-0000-0000-0000-000000000005	Infrastructure Audit	SX-001	Security and performance audit of their cloud setup	active	#FFB347	{devops,security,audit}	12000	hours	40	\N	2025-04-01	2025-04-30	\N	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
\.


--
-- Data for Name: schema_ardine_short; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.schema_ardine_short (id, table_name, content, embedding) FROM stdin;
1	clients	Table: clients\nDescription: ลูกค้าของแต่ละ team เป็นเจ้าของ project และ invoice มีอัตราค่าบริการ default และสถานะ archive\nColumns:\n  id                        UUID PRIMARY KEY,                                    -- รหัส client\n  team_id                   UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE, -- FK → teams: team เจ้าของ client\n  name                      VARCHAR(255) NOT NULL,                               -- ชื่อบริษัท/ลูกค้า unique ภายใน team (case-insensitive)\n  email                     VARCHAR(255),                                        -- อีเมลหลักสำหรับติดต่อ\n  phone                     VARCHAR(50),                                         -- เบอร์โทรศัพท์\n  contact_name              VARCHAR(120),                                        -- ชื่อผู้ติดต่อฝั่งลูกค้า\n  billing_address           JSONB,                                               -- ที่อยู่ billing สำหรับออก invoice เก็บเป็น JSON object\n  tax_id                    VARCHAR(64),                                         -- เลขประจำตัวผู้เสียภาษีของลูกค้า\n  notes                     TEXT,                                                -- โน้ตภายในสำหรับทีม ลูกค้าไม่เห็น\n  default_hourly_rate_cents INTEGER,                                             -- ราคาต่อชั่วโมง default หน่วยสตางค์ เช่น 12000 = 120 บาท/ชม. (project และ task สามารถ override ได้)\n  currency                  VARCHAR(3) NOT NULL DEFAULT 'USD',                   -- สกุลเงิน เช่น THB, USD, SGD\n  archived_at               TIMESTAMPTZ                                          -- ถ้ามีค่า = client ถูก archive แล้ว ไม่ active แต่ยัง query historical data ได้\n	[0.007734968,0.029596396,-0.031811453,0.0036126666,-0.018792871,-0.03861752,-0.04069686,-0.021978728,0.047130093,0.020073378,0.032272056,0.0060513103,0.11079024,0.04099121,-0.014256317,-0.023308346,0.0020932327,-0.02640956,0.013165712,-0.014049283,0.055032115,-0.04876262,0.024081415,-0.0043847286,0.013905806,-0.022667687,-0.0046078116,0.00070083904,-0.039592598,0.045356054,0.026209915,-0.021000009,0.009227497,0.053211715,0.016427394,0.028847761,-0.0037117493,-0.029730706,-0.0008569852,-0.022351079,0.029766379,0.0005104572,0.04919892,-0.03345701,0.02099416,-0.011551774,0.06605238,0.0036373886,-0.031323094,-0.007170907,0.029985355,0.0057553654,0.06235851,0.0071576843,-0.050798137,-0.0034931803,0.029754266,0.049986858,-0.032185126,-0.012400466,-0.004428873,0.04506565,-0.00020452951,0.011448021,0.027232733,-0.013674574,0.022539416,-0.03446735,-0.049168926,-0.030415256,-0.011203343,0.009372939,0.113364875,-0.00076063524,-0.01746494,-0.0056217597,-0.03623194,0.0006253444,0.015285291,0.0012995057,0.060677078,0.005619059,0.0041256743,0.03227068,0.01579789,0.004112538,-0.040700056,0.037369676,0.03305129,0.038227715,0.021452265,-0.03386076,-0.04131839,0.03550706,0.03939741,0.027516179,0.006155201,0.007888307,0.044012707,-0.03150144,-0.010943899,-0.08502605,-0.01601514,-0.016283259,-0.08882569,-0.03248857,-0.0040784916,-0.041580826,0.05068799,-0.042581245,-0.022924967,0.012620945,0.026112573,-0.04446678,0.02483517,-0.0343215,0.065679304,-0.06023596,0.013125803,-0.07490629,-0.051157482,-0.0036526753,-0.00061251456,-0.013614038,0.046972957,-0.027346678,-0.010845574,-0.008761267,0.015406574,-0.0643836,-0.04653863,-0.044496786,-0.00816209,0.016482037,-0.014980662,0.049698703,0.040764198,-0.010747948,-0.0050810305,0.011483836,0.04735582,-0.04139174,0.0125477165,0.067779295,0.005077129,-0.06116136,-0.020710943,0.014471718,-0.026976394,0.029104099,0.042683564,-0.072030045,-0.04504097,0.0022963895,0.0340013,0.0040841824,-0.046196952,-0.014042357,0.02022644,0.01914791,0.0074123815,-0.013145907,-0.00010042851,-0.028667906,0.040996876,0.010020014,-0.014001553,0.006362535,-0.044474192,-0.00992617,-0.010786837,-0.05118623,-0.08397818,0.030374084,-0.016673457,-0.037524253,-0.013281493,-0.018689673,-0.025900023,-0.04786187,-0.072077766,0.0070412843,-0.032165505,0.020600785,-0.02713109,-0.009640624,-0.03252079,-0.024262566,0.04426707,0.001720491,-0.0015844713,0.1025849,0.007109418,0.047177695,0.029764377,0.016971188,0.013784742,0.014707706,-0.003991318,-0.04922909,-0.001424195,0.0055977837,0.040612023,0.044564057,0.0041619097,-0.04510519,0.0056164875,0.038836386,-0.00817926,0.034821335,-0.016844595,0.042427268,-0.03157513,0.034936536,-0.04131539,-0.050818626,0.03160461,0.03249362,-0.010210002,0.036148544,0.0025358354,-0.05730515,0.058305267,0.045926873,-0.024409248,0.0060414136,0.004909056,-0.024850916,0.02741426,0.015238671,0.033103894,0.110836215,-0.02720788,0.028047968,-0.008601904,-0.0039789286,0.04262861,-0.015178724,-0.0069169677,-0.10044529,-0.05853659,0.025447048,0.009551127,-0.020243976,0.03137685,-0.016649103,-0.045232825,0.046029884,-0.052882154,0.017094838,0.037720747,-0.06338679,0.004450621,-0.0064265453,0.016821874,0.009729037,-0.03393263,0.013830434,0.043943517,0.0029541666,-0.00046563594,-0.008506328,0.0019599334,-0.031204436,0.015536431,-0.006225276,0.0039434657,-0.026500763,-0.05916269,-0.011297169,-0.004209793,-0.03218018,-0.0411647,0.02471569,0.015309153,0.0015910742,-0.049652267,0.011438369,-0.008788757,-0.07128223,-0.015071428,0.034528617,-0.05585555,-0.0018963007,-0.0213332,0.009370788,-0.05516971,0.00026554315,-0.030421691,-0.0099652205,0.018843956,0.09756881,-0.008432571,-0.0060401633,0.047014702,0.016408145,0.026755242,0.005683306,-0.0042659775,0.0063787242,-0.025119528,-0.02206581,0.028874533,-0.059356965,-0.023600334,0.025747225,0.13284683,0.028532574,-0.063242756,0.04200398,-0.022952432,-0.0057020723,-0.002342616,0.05029242,0.045352515,-0.06283019,0.0104398765,0.060482234,-0.0043118624,0.023595579,-0.031930067,0.020121101,-0.012840254,-0.062418908,0.04367053,-0.037334006,0.030259548,-0.008098453,0.026257418,0.030439699,-0.017024461,0.017976014,0.037117686,0.023760118,-0.050106004,0.018372195,-0.06718876,-0.034804836,0.06635101,0.010691616,-0.028122006,0.03039182,0.03418936,-0.015723638,0.063338585,-0.07195731,-0.017283548,-0.05272968,-0.042041175,-0.0070542013,0.022368629,-0.04125496,0.023752773,-0.012884833,-0.032390747,0.00812314,0.00854104,-0.003252686,-0.017158942,-0.0068161455,-0.0041965195,0.023466876,0.037105888,-0.0072916197,0.03081566,0.028372092,-0.064084694,-0.022691844,0.015859045,0.016304716,0.08807391,0.05648142,-0.028573371,0.005947992,0.055171326,-0.021110477,0.026613006,-0.07217079,-0.021203466,0.034432486,0.047000017,0.026721442,0.032386642,0.02975108,-0.056190092,-0.011077893,0.026640268,-0.04122966,0.0440791,0.0015194819,0.04075375,0.0043654335,-0.021177428,0.047190275,0.05070068,-0.034016665,0.005727301,0.0017854018,0.025539115,-0.048792463,0.07527643,0.007895109,-0.02896925,0.06289666,0.04114856,0.022406414,-0.012182549,0.05391956,0.027608259,-0.028936625,0.023237599,-0.048460923,0.06511612,-0.01004017,0.019187497,-0.010977316,0.007211727,0.032468762,-0.0021129807,0.023084618,-0.05766375,0.0050567044,0.020442782,-0.0048389165,0.030461453,-0.072539724,0.014342293,-0.007694996,-0.00655989,0.005998381,-0.035569716,0.0014870005,-6.5016895e-05,0.003303859,0.0132390335,-0.029817114,0.0011512971,0.02008361,-0.016973536,0.0005672536,-0.017749725,-0.019844865,0.013132016,-0.0076247514,-0.018099103,0.009722495,-0.037176378,0.026705336,-0.023558753,-0.015866917,-0.015772847,-0.018281687,0.021162318,-0.0056917,0.03913843,-0.041175812,0.06736865,-0.013322893,0.006082969,-0.11378342,-0.00730183,0.0419333,0.0063611367,-4.3555585e-05,-0.032898843,-0.052299995,0.022982934,-0.04368883,0.041225825,0.0016425863,-0.043044128,-0.014961261,-0.002236692,0.03984841,-0.0099314395,0.03703783,-0.002171859,0.01999587,0.026972929,-0.008208121,0.022024816,-0.0030680934,-0.032769386,0.008431446,0.006906889,0.0523862,-0.108074516,0.028032092,0.04777942,-0.052495033,-0.033004113,0.043081306,0.033165805,-0.011083547,0.0021783703,0.04713111,0.019487118,-0.049196273,0.03849369,0.020677548,-0.022718867,-0.034351952,-0.040395442,0.007110002,-0.027521225,0.0062243943,-0.029580276,0.044335697,0.045879874,-0.05793895,0.14104964,-0.0099716345,-0.021440784,-0.015509822,0.013471809,0.010432989,-0.010069195,0.017710498,0.0077806627,-0.037537873,-0.013976819,0.0074151275,-0.034500234,-0.020541783,0.031573407,-0.04456183,0.0028670675,-0.026433015,0.05675977,-0.020150432,0.026340807,-0.025225734,0.041347153,-0.11210888,-0.06134519,0.031252448,-0.018756792,-0.010876103,0.036640707,-0.044799186,-0.006231543,-0.009937933,0.032039013,-0.019798901,0.008630816,-0.058116987,0.043771252,-0.031051777,-0.017238861,-0.021889988,0.060082342,-0.0057595125,-0.046539757,0.039681844,-0.010761202,0.05422324,0.03468546,0.016386587,0.0016477101,-0.02630302,0.027273076,-0.03248385,0.0023790896,0.024725392,0.0133388955,0.0022291678,0.035084113,-0.025039785,0.006722074,0.06572173,-0.06559723,0.010720751,0.03747532,-0.014931971,0.023791445,0.03332391,-0.027422622,-0.013692439,-0.0040898025,-0.058274917,-0.057294976,0.0036913524,0.023740806,0.026806472,0.019272357,-0.016792543,0.019199677,0.004624646,-0.20625454,0.01456083,-0.01629017,-0.04430012,-0.00023881243,0.030705983,0.03813197,-0.027804138,-0.008844883,0.040972203,0.038757432,-0.026102308,0.019974975,-0.030658389,-0.031305373,0.011331563,-0.010622534,-0.0062430417,0.021637214,0.017187461,0.003606103,0.07261496,-0.044117723,-0.02572544,-0.026811106,-0.039295673,-0.007496993,0.015421951,0.022889247,0.009678845,0.045708776,-0.004315038,0.033874027,0.024133407,-0.026775517,-0.01562517,-0.00707429,-0.0066194925,-0.09024548,0.038972136,0.021067757,-0.019575605,-0.048128147,0.0237613,0.009800929,0.04471708,0.0054949704,0.036853954,-0.020363824,-0.008360504,0.02097874,0.009074058,-0.10479387,0.011612214,-0.011551044,0.058907345,0.036284976,0.009068642,0.040160175,-0.0259298,0.06627561,0.067365885,-0.02748671,-0.0043342975,-0.012209424,0.01148247,0.05136135,-0.031214224,0.0023589951,0.03226935,0.06134168,-0.030910717,-0.008180781,-0.0051860074,0.03396183,-0.057871386,0.028195513,-0.018366609,-0.053644825,0.011133483,-0.0334609,-0.03860707,-0.010913551,0.033407383,-0.040433045,-0.047740158,-0.06389493,0.025941547,0.041902658,0.025476051,-0.015050951,-0.027346598,-0.011899403,-0.002774942,0.016122652,-0.026651464,-0.058065176,0.0034581784,-0.022395102,-0.027569091,0.029017853,0.0009122427,-0.0386315,0.023294477,0.034377176,-0.040493995,-0.12327307,0.03470812,-0.039898224,-0.04481963,0.057550646,0.042699933,0.047861952,-0.019659264,0.01229932,0.024633318,0.012979579,-0.019140093,-0.036436353,-0.059957042,-0.018830376,-0.005831676,0.004283664,0.016303364,0.031183422,0.017081179,-0.035335653,0.03703845,0.01272351,0.028835615,0.018527988,-0.061498396,0.027569124,-0.011696607,-0.039747342,0.017573025,0.024466686,-0.011638963,0.02501747,0.014687843,0.073287934,-0.05376043,-0.03127282,0.05033431,0.005386607,0.020308355,0.0042309654,0.0011781879,0.012518957,-0.01668821,-0.024538506,-0.09494671,0.0013669609,-0.017920598,-0.004960353,0.023626164,0.012812998,0.020972572,0.02524644,0.03307409,0.0050911186,-0.04578838,-0.012447966,0.0042615584,0.00063658966,-0.0059854444,0.00047096776,-0.062496755,-0.011116053,0.016519032,-0.041614506,0.0403261,0.028813213,0.025844812,0.004970366,-0.023064049,0.056353305,-0.0068606213,-0.0052233706,0.016049732]
2	invites	Table: invites\nDescription: คำเชิญเข้าร่วม team ที่ยังรอการตอบรับ มี token สำหรับสร้าง invite link และมีวันหมดอายุ\nColumns:\n  id          UUID PRIMARY KEY,                                    -- รหัส invite\n  team_id     UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE, -- FK → teams: team ที่เชิญเข้า\n  email       TEXT NOT NULL,                                       -- อีเมลของผู้ถูกเชิญ\n  role        TEXT NOT NULL,                                       -- role ที่จะได้รับเมื่อ accept: OWNER / ADMIN / MEMBER / VIEWER / BILLING\n  token       TEXT NOT NULL UNIQUE,                                -- token สุ่มสำหรับสร้าง invite link\n  expires_at  TIMESTAMPTZ NOT NULL,                                -- วันหมดอายุ invitation ที่เลยวันนี้และ accepted_at IS NULL = expired\n  accepted_at TIMESTAMPTZ,                                         -- เวลาที่ accept NULL = ยังรอการตอบรับ\n  created_at  TIMESTAMPTZ NOT NULL                                 -- วันที่สร้าง invitation\n  -- UNIQUE (team_id, email): invite ได้แค่ 1 ครั้งต่อ email ต่อ team\n	[0.014596496,0.02606932,-0.024541628,0.039797742,0.012663827,-0.04892678,-0.031190207,-0.025234576,0.031691376,0.004492189,0.016339067,0.00042569343,0.11650138,0.04900106,-0.026808023,-0.017858766,0.0077836695,-0.015249551,-0.0031766864,-0.01580481,0.06136811,-0.053508524,0.034162268,-0.013416613,0.025358267,-0.020895049,-0.011857135,-0.0048091183,-0.038140267,0.023828449,0.038705282,0.004469889,-0.022571363,0.026085733,0.023770537,0.01203279,0.006943404,-0.010239238,-0.002362004,-0.006528468,0.038802657,-0.003997773,0.0503587,-0.034864195,0.036225833,-0.017904034,0.06087675,0.032526117,-0.015302022,-0.027546354,0.023306524,0.025154272,0.04052396,0.012232127,-0.030641267,-0.027488383,0.021123732,0.03759293,-0.028575407,0.014660801,-0.010294145,0.025313098,-0.00013748066,0.04195282,0.04724507,-0.010989396,-0.014163221,-0.038165066,-0.05463313,-0.01935002,-0.012225219,0.024760697,0.09185856,-0.004384093,-0.023150422,-0.012867194,-0.05013215,0.019784968,0.002874863,-0.016072648,0.05378785,0.0069848765,0.021100016,0.019040959,-0.010344864,-0.015832022,-0.017104002,0.04586419,0.043804962,0.016741913,0.013607001,-0.042812455,-0.049463224,0.0073460215,0.041359294,0.026186395,-0.006146048,0.0050351294,0.042997263,-0.056655157,-0.0021840793,-0.08114069,-0.037821077,-0.04515647,-0.08633266,-0.036900405,-0.011193631,-0.04278964,0.047170687,-0.026432576,-0.005453515,0.008342839,0.011361772,-0.05998289,0.03494832,-0.039586045,0.062426053,-0.064577185,0.02722806,-0.054526236,-0.054636486,0.028556304,-0.014335581,-0.016270908,0.055525575,-0.028908487,0.00026889332,-0.017367521,0.0224991,-0.06219782,-0.04349936,-0.031584505,-0.0035902301,0.010831345,-0.004375391,0.055977955,0.039728552,-0.0063053626,-0.0025121043,-0.014651461,0.021419443,-0.035449494,0.011162801,0.040480427,0.016138295,-0.06371964,-0.0057944753,0.013149226,-0.01862759,0.009630438,0.04482651,-0.05712747,-0.039280687,-0.0016711139,0.044418417,0.0037189135,-0.052433338,-0.014699639,0.017855803,0.034384076,0.041716818,-0.012745835,0.036466137,-0.039518088,0.047097165,0.017869255,-0.014690935,0.021738337,-0.030336391,0.01414134,0.0018143913,-0.031160142,-0.08118667,0.038614787,-0.022683218,-0.035977952,-0.010347666,-0.03405482,-0.021608563,-0.048149325,-0.085085675,0.019211791,-0.040373966,0.024994234,-0.01995127,-0.027531138,-0.015777845,-0.021254664,0.064800434,0.004679455,-0.014152825,0.075033665,0.014716366,0.041371707,0.043215442,0.0015968769,0.022875337,0.026116373,0.018533228,-0.04494405,0.014682489,-0.014918736,0.047659837,0.031219129,0.018168734,-0.07903864,-0.008398273,0.046172425,0.011748358,0.015610982,-0.024228258,0.052429795,-0.027308064,0.05518485,-0.03983012,-0.019038491,0.018955361,0.024050614,-0.0064561586,0.04517826,0.004727494,-0.03569065,0.072145805,0.049180377,-0.02201611,0.014723791,0.01575224,-0.0070593483,0.034084123,0.03982927,0.049981758,0.0878322,-0.021430457,0.0201977,-0.014059601,-0.022424836,0.0028253691,-0.00942036,-0.011280952,-0.10134106,-0.029924488,0.027610475,-0.0037407982,-0.016339714,0.0028399627,-0.027187053,-0.025935844,0.03815667,-0.049798917,0.01900064,0.046227075,-0.038762935,-0.004199172,-0.02479713,0.015476599,0.011532044,-0.044638462,0.024310132,0.048581075,0.0047316016,-0.0016402303,0.013269412,-0.0027973303,-0.04317749,0.0036925746,-0.0036018672,0.038045198,-0.027916394,-0.042160645,-0.017563976,0.012750147,-0.03257109,-0.029556686,0.00844128,0.03860552,-0.01840905,-0.07498408,0.013459237,-0.00870602,-0.057262532,-0.036574204,0.06094497,-0.06486742,-0.049520425,-0.026729451,0.0028872127,-0.050781213,0.0061354632,-0.04548701,0.0013194998,0.032251686,0.0762034,-0.013434296,0.0053686025,0.0563167,0.008581359,0.049102698,0.0040881527,-0.02229367,0.006920914,-0.027745184,-0.022945493,0.03280058,-0.052236464,-0.0066909553,0.023306238,0.12761694,0.0014112432,-0.054646503,0.054481544,-0.020128308,-0.014050278,-0.03230464,0.06958143,0.032049224,-0.029216766,0.0018774788,0.06599127,-0.0051541594,0.04019706,-0.025066916,0.024218168,-0.0036451034,-0.06193393,0.03756128,-0.04797018,0.038406357,-0.0083287135,0.073009446,0.027548864,-0.018276732,-0.0029625422,0.009355752,0.046192188,-0.057630178,0.024998657,-0.06303786,-0.028341651,0.06611003,0.009459116,-0.029528644,0.02453211,0.031239022,-0.022550525,0.031051038,-0.08855657,-0.019389043,-0.05477153,-0.04447679,0.0015103454,0.039921883,-0.0637049,0.011777146,-0.015579721,-0.026231477,-0.0017867833,0.016422795,-0.015255899,-0.020530852,0.008666459,-0.008897162,0.030295782,0.021127494,0.0096077155,0.028168935,0.033058316,-0.06619657,-0.018532244,-0.0074981204,0.004080953,0.10695294,0.050084293,-0.04984609,-0.010108393,0.030086383,-0.033423174,0.018453354,-0.046548776,-0.008889517,0.03448479,0.03055677,0.04763565,0.031848848,0.029818801,-0.064670935,-0.0035453932,0.016798263,-0.05777077,0.024103912,-0.018388178,0.048529785,-0.0037446567,0.0012278712,0.030663783,0.04088264,-0.03597205,0.009041674,-0.0032814476,0.030334434,-0.060696132,0.05562408,0.012187843,-0.0014301778,0.05757327,0.05020612,-0.00068704935,0.0024509134,0.055405274,0.032343008,-0.032960176,0.02699429,-0.051886212,0.040974736,-0.017387155,-0.0027113243,-0.02895046,0.009447984,0.049894404,0.002155273,0.024027152,-0.057236277,0.011521928,0.027208237,0.015584669,0.025286084,-0.07595584,-0.0022279394,-0.006721537,-0.0022653379,-0.018481992,-0.029944155,0.009674534,-0.0127021745,-0.015740734,0.008112944,-0.037212335,0.017114585,0.04128625,-0.032495536,0.0044069155,-0.004402531,-0.031611253,-0.00047939928,-0.0058534485,-0.016091047,-0.02671484,-0.06626811,0.0147365425,-0.03172152,0.019191895,-0.007304153,-0.012682945,0.012928602,0.0053144554,0.05366189,-0.05008208,0.06009329,-0.042648748,0.0032149202,-0.12095695,0.029738987,0.06305188,0.0024524052,-0.0023319535,-0.04123656,-0.074581444,0.0020286166,-0.043931894,0.05672229,-0.020460933,-0.008290108,-0.0014117975,0.012186686,0.04506695,-0.0056517613,0.04182205,-0.038454954,0.009515602,0.02866206,-0.020177001,0.028867347,0.00077903375,-0.03549496,-0.009064458,0.019132411,0.04022772,-0.10999375,0.03491419,0.03158754,-0.0491849,-0.026108531,0.0356,0.048818197,-0.0007629024,-0.021302553,0.022658512,0.010487292,-0.06904974,0.033140678,0.037169404,-0.025010945,-0.03344604,-0.052174315,0.0010221931,-0.034465298,0.029785402,-0.012307285,0.022247633,0.043793608,-0.036623865,0.13611987,-0.011756953,-0.007986655,-0.010518829,0.029445194,-0.015733216,0.009626484,0.031763103,0.016461283,0.0041725016,-0.01988398,-0.017662425,-0.047449604,-0.0154689,0.034129925,-0.059220582,0.012876824,-0.01644617,0.046459053,0.012749119,0.01900133,-0.034510873,0.024117861,-0.10930282,-0.06673493,0.03248866,-0.01755464,-0.01339026,0.04897718,-0.042218197,-0.031560123,0.0041576517,0.027285876,-0.040294025,0.024651015,-0.050170768,0.032452397,-0.026347833,-0.00035686805,-0.0036754555,0.047236446,0.0061284206,-0.03932463,0.036946934,-0.02184762,0.0479013,0.04074579,0.017968185,0.017546378,-0.02613784,0.031592783,-0.024497652,0.005248902,0.023273228,-0.0024946483,-0.0027597316,0.01896669,-0.030647852,-0.021520302,0.056726333,-0.065291494,0.028868474,0.041876655,-0.0039000928,0.053720683,0.033896446,-0.012573178,-0.015011561,0.0051829224,-0.05209395,-0.048424806,-0.00197225,0.0057487437,0.014213222,0.04675255,-0.012882989,0.03629688,0.020869365,-0.21151441,-0.0007162171,-0.015214854,-0.01073178,-0.021031603,0.047339454,0.008479719,-0.03132844,-0.006270005,0.028944254,0.04591011,-0.054300148,0.00834605,0.0057272925,-0.03685562,0.005471226,-0.021624796,-0.038896684,0.00403843,0.008235156,0.014817385,0.06567127,-0.058146134,0.017501712,-0.038509693,-0.03007338,-0.023139236,0.009180053,0.011633298,0.010487987,0.018407311,-0.018398566,0.037172385,0.008750798,-0.014087825,0.00096510287,-0.011791487,0.012961294,-0.087994665,0.046000507,0.01536251,-0.015750838,-0.053932123,-0.002361909,0.012037689,0.06436306,0.024475865,0.056726247,-0.0096396245,-0.024365854,0.0013009984,0.010023703,-0.07234718,-0.00871668,0.009354222,0.022035416,0.028192367,0.012375708,0.048920162,-0.010726283,0.046542883,0.0663228,-0.040036976,-0.0043761954,-0.01427679,0.022068651,0.047153052,-0.039473414,-0.008371446,0.019915543,0.04571743,-0.040064387,-0.030105863,-0.008233453,0.014144308,-0.043027487,0.01687464,-0.0016124818,-0.066301815,0.020398946,-0.020949638,-0.03146683,-0.007028087,0.03269594,-0.042396426,-0.03712602,-0.04079546,0.020028502,0.030359523,0.014634811,-0.017212318,-0.03531515,-0.013019024,0.014350294,0.0013456758,-0.030606352,-0.026750654,0.011028526,-0.005385144,-0.023786869,0.025047794,-0.012199949,-0.048996758,0.020172592,0.017767744,-0.015834197,-0.11747483,0.043268897,-0.018985849,-0.055383198,0.056928657,0.023499727,0.04279096,-0.02092312,0.0014816484,0.01156813,0.0047124187,-0.03974583,-0.03687791,-0.03795107,-0.024815885,-0.024989909,0.021070637,-0.0067916745,0.04128352,0.018371562,-0.01536593,0.051104233,0.027234096,0.03823166,-0.0043595256,-0.06541768,0.03748962,-0.010337564,-0.021578925,0.023614809,0.029251238,-0.007127477,0.031176485,0.03428652,0.045433763,-0.064758785,-0.022687878,0.040480096,0.029852245,0.032124396,0.018123826,-0.030028554,-0.0084644295,-0.012943763,0.0012322124,-0.09367773,0.010690748,-0.016537538,-0.004410511,0.014762371,0.040633414,0.022529552,0.0126312,0.01340237,0.0036629462,-0.046825018,-0.003757249,0.015555033,-0.007223662,-0.010695646,-0.00023937099,-0.040498354,0.016180782,0.023928154,-0.01804846,0.033066656,0.022977667,-0.012027314,0.010723525,-0.016208267,0.039798453,0.01884374,-0.00934098,0.030747514]
3	invoice_items	Table: invoice_items\nDescription: รายการย่อยแต่ละบรรทัดใน invoice แต่ละ item อธิบายค่าบริการ จำนวน และราคา สามารถเชื่อมกับ time entry ได้\nColumns:\n  id             UUID PRIMARY KEY,                                          -- รหัส item\n  team_id        UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,       -- FK → teams\n  invoice_id     UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,    -- FK → invoices: invoice ที่ item นี้สังกัด\n  time_entry_id  UUID REFERENCES time_entries(id) ON DELETE SET NULL,       -- FK → time_entries: time entry ที่เชื่อมกับ item นี้ (NULL = fixed-price item)\n  description    TEXT NOT NULL,                                              -- คำอธิบายรายการ เช่น "Frontend Development"\n  quantity       NUMERIC(10,2) NOT NULL,                                     -- จำนวน เช่น ชั่วโมงทำงาน 8.50\n  rate_cents     INTEGER NOT NULL,                                           -- ราคาต่อหน่วย หน่วยสตางค์\n  amount_cents   INTEGER NOT NULL,                                           -- ยอดรวมของ item = quantity × rate_cents\n  created_at     TIMESTAMPTZ NOT NULL 	[0.010492766,0.030060502,-0.012146475,0.016971532,-0.0047691762,-0.0286291,-0.023222923,-0.010629203,0.04388308,0.018916091,0.028087765,0.002088678,0.11785043,0.0559876,-0.02579821,-0.025767267,0.010919302,-0.0035282094,0.017858563,-0.027531674,0.06482206,-0.05666449,0.044718094,-0.014262501,0.006511613,-0.030182768,0.0065043764,0.005313942,-0.056495633,0.05047007,0.03704406,-0.0107454425,-0.0019293779,0.049963042,0.009425056,0.0018043336,-0.013391011,-0.028294366,0.0049943584,-0.017706094,0.04324869,0.011000463,0.033450536,-0.020399088,0.020062117,-0.019339785,0.07009988,0.0203123,-0.023703333,-0.011475733,0.036051277,0.0072417553,0.04227216,0.005133554,-0.060299806,0.017144881,0.03826937,0.043767568,-0.02126929,0.00063235813,0.006906383,0.045335837,-0.0097490875,0.016986085,0.022742592,-0.019308442,0.01934324,-0.0363386,-0.04668438,-0.030346215,-0.005681002,0.02475347,0.1022429,-0.025433347,-0.023030087,-0.011781323,-0.044074513,-0.012719532,-0.0011595535,0.0044057895,0.061423868,-0.0038746647,-0.009723194,0.031529367,-0.0008182421,-0.0037878044,-0.03316911,0.035097633,0.021931663,0.020935314,0.02791261,-0.019872477,-0.050940543,0.007912329,0.043213535,0.033377327,-0.005748278,0.02084541,0.022164615,-0.02413909,-0.0046558017,-0.07992059,0.0058134217,-0.024563149,-0.08862731,-0.019295152,-0.02086843,-0.04824132,0.07531698,-0.015503538,-0.021365715,0.014805613,0.038308706,-0.06371603,0.041578453,-0.040787466,0.0625289,-0.048090223,0.0069333417,-0.074572235,-0.045028426,-0.0031153478,-0.00468664,-0.02963453,0.04930623,-0.023713715,0.0063454323,-0.006902483,0.013476022,-0.045494914,-0.028531522,-0.05726827,-0.0026153182,0.02296349,-0.021985926,0.03196604,0.05502236,-0.0013535157,0.00092401035,0.01184725,0.043018926,-0.022008419,0.005646152,0.066150405,0.008347615,-0.055353966,-0.0125217745,0.0064461166,-0.016906466,0.038037434,0.028499756,-0.057059813,-0.036918692,-0.00020178226,0.031968962,0.006729639,-0.031374022,-0.01672064,-0.0005953611,0.032606006,0.012125359,-0.020864189,0.0016380829,-0.033605434,0.053883,0.01136749,-0.026130522,0.037436105,-0.047246408,-0.0018796732,0.012616772,-0.04200152,-0.088965535,0.040251914,-0.01977469,-0.031224625,-0.015411874,-0.018287418,-0.030969044,-0.043994453,-0.057328384,0.009927844,-0.053547837,0.0172545,-0.008976319,-0.0012909998,-0.028430894,-0.033809777,0.033602953,0.005063343,-0.006797645,0.10104566,0.0026815962,0.044002652,0.017821575,-0.00866141,0.036801793,0.023126753,-0.003437852,-0.03844488,3.215586e-05,-0.0029936524,0.03419979,0.03330436,0.0014732127,-0.050280746,-0.0023448796,0.04102387,0.0126662105,0.03447208,-0.04506131,0.03193868,-0.015344419,0.03332209,-0.02381746,-0.058354866,0.03909012,0.036225963,-0.034154203,0.031407934,0.005576626,-0.058525987,0.052152276,0.04986316,-0.013621359,0.004225755,0.017406099,-0.023160318,0.040127575,0.0095252525,0.032625448,0.113747545,-0.032118615,0.010171114,-0.007936514,-0.0063189636,0.044768963,0.004520406,-0.025438813,-0.09844949,-0.052271627,0.024838947,0.016207134,-0.0200586,0.028949745,-0.004666385,-0.04799543,0.041764885,-0.06275378,0.009534727,0.04097132,-0.056655265,0.008950455,-0.025516167,0.028223854,0.0014752994,-0.041895363,0.0095737865,0.037640445,0.003941001,0.00064194336,-0.010480172,0.008849958,-0.027697211,0.009998619,-0.0062939767,0.0012428974,-0.045530736,-0.03262324,-0.0070574633,-0.007335367,-0.032461196,-0.037237283,-0.004101272,0.010054677,-0.003867809,-0.04352141,0.016100463,-0.015717676,-0.06738387,0.0022003732,0.044476595,-0.060719047,-0.022450015,-0.035842095,0.005184779,-0.066066556,0.0024107117,-0.03264475,-0.0025988054,0.016553346,0.09438845,-0.011162674,0.002090316,0.026320148,0.017793324,0.044819735,0.011259057,-0.007710259,0.0011493304,-0.023392426,-0.016830582,0.013134508,-0.052116767,-0.03550662,0.027451783,0.12635949,0.025898468,-0.0427967,0.039608885,-0.026949178,-0.017298143,-0.01036602,0.03468269,0.04434534,-0.05476659,0.0021288274,0.05806225,-0.0101752095,0.034932278,-0.020223482,0.035011154,-0.011693077,-0.06991131,0.03968339,-0.047151368,0.030324398,-0.020718757,0.059068665,0.016754009,-0.015870923,-0.0030190046,0.017950427,0.026334457,-0.053963594,0.023558704,-0.08173311,-0.04290364,0.05330622,0.011927135,-0.022639476,0.030536478,0.029688278,0.00061138265,0.056146998,-0.080946065,-0.02185211,-0.06229025,-0.052260984,0.0073182955,0.0058930153,-0.052011613,0.003484562,-0.005742806,-0.03573516,0.006101249,0.03260549,-0.024562847,-0.02026718,-0.013552698,0.008630866,0.021416178,0.027741503,-0.015384364,0.030699937,0.021254277,-0.06515394,-0.03277245,-0.00402564,0.0007574046,0.09995607,0.054128073,-0.017485812,0.0066399937,0.034260154,-0.030834144,0.036062755,-0.059585266,-0.012295643,0.018199516,0.042517323,0.03981584,0.02663127,0.04040905,-0.04630632,-0.004716898,0.030747091,-0.04960239,0.033692863,-0.007114746,0.036611114,-0.03040901,-0.013905939,0.04042376,0.049115505,-0.04637376,-0.008563786,-0.007352662,0.022752745,-0.046695903,0.07162958,0.01047171,-0.021376604,0.0609002,0.028077452,0.03366174,-0.0057603978,0.055740748,0.044165283,-0.035178266,0.036967278,-0.052928235,0.054170325,-0.00989983,0.008722846,-0.019570453,0.016116284,0.033458028,0.0020044427,0.025157295,-0.08163476,0.04220786,0.034846958,-0.009282743,0.031585794,-0.08012554,-0.0035258739,-0.000118913005,-0.0005986555,0.003238052,-0.024739627,0.02085381,0.012862455,0.0019520271,0.019308975,-0.045427263,0.014257145,0.03186603,-0.020865168,0.004624022,-0.0086774845,-0.035898767,0.024179177,0.002441382,-0.01703476,-0.0008933052,-0.04664134,0.02913634,-0.00035070235,-0.0038375075,-0.017258676,-0.0058415667,0.026756667,-0.0032597058,0.041105263,-0.043443646,0.069550484,-0.014760695,0.0040617203,-0.12604694,0.03294484,0.044492263,-0.0055675516,-0.00388398,-0.037776146,-0.07224936,0.010218999,-0.04250273,0.03622484,0.00079172506,-0.023198215,0.004658391,-0.014254735,0.03722645,0.012928189,0.031802528,-0.009434797,0.013943706,0.033959467,-0.00058241986,0.051065914,-0.014004603,-0.0139311785,0.0024443665,-0.0004226272,0.043230306,-0.105792366,0.036674436,0.031251434,-0.047493488,-0.027319878,0.021386815,0.049019296,-0.026581151,-0.017844962,0.044252407,0.006796397,-0.057718668,0.050474517,0.038392227,-0.012048589,-0.035148617,-0.045122974,-0.0026607146,-0.04244544,-0.0052492484,-0.025002612,0.034763597,0.04556094,-0.042304352,0.12956877,0.0028355364,-0.019554315,-0.0037768383,0.014029211,-0.0078256475,-0.01722373,0.024885342,0.016807992,-0.027646357,-0.021444643,0.019001609,-0.022809744,-0.030263403,0.025762174,-0.05100125,0.014405098,-0.049726106,0.038195837,-8.650014e-05,0.021809923,-0.036341187,0.033297483,-0.10835034,-0.057665106,0.04461031,-0.0048745233,-0.004852318,0.039226208,-0.02975298,0.009934645,-0.018488478,0.022263084,-0.031889863,0.016397264,-0.05749727,0.016394762,-0.015504647,-0.0053783427,-0.010270076,0.052398548,-0.008536566,-0.031772077,0.04478072,-0.01652017,0.050174844,0.033690825,0.012852991,-0.0029921005,-0.019925738,0.01964478,-0.033010952,0.014308228,0.013615116,0.026394317,-0.0038077799,0.026839172,-0.022740986,-0.012247939,0.045640383,-0.054623228,0.033211816,0.026985947,-0.009861621,0.02367759,0.021015882,-0.031171357,-0.013598145,-0.015372492,-0.05520798,-0.028814768,0.0050143693,0.009484314,0.044285703,0.045324083,-0.005354341,0.016211933,0.016499205,-0.2171812,-0.005373154,-0.012642709,-0.041516606,-0.007870308,0.04652948,0.014522393,-0.02196807,0.004164588,0.018365229,0.041680407,-0.011220617,0.010358972,-0.044300776,-0.035645254,0.022121675,-0.005580054,-0.020788247,0.006589876,0.024132457,0.0022810514,0.08215395,-0.033169437,-0.0006372516,-0.031275272,-0.047329552,-0.009040092,0.029277107,0.016952751,6.078441e-05,0.020287354,-0.013494732,0.03110329,0.011653744,-0.0223386,-0.025497109,-0.0044080843,3.282869e-05,-0.09239466,0.050620362,0.034487236,-0.016662968,-0.049723327,0.013385261,-0.0018392649,0.04878145,0.006569824,0.049780276,-0.027874501,-0.020474082,0.009023847,0.012750266,-0.091030374,2.8949471e-05,0.0026058163,0.059141107,0.024659095,0.00030295344,0.039212495,-0.017647639,0.06913609,0.05418525,-0.035693724,-0.0038405107,-0.009896553,-0.008091347,0.03579969,-0.031158343,0.0009569955,0.023738038,0.045985658,-0.036690313,-0.018632354,0.0005964168,0.04495257,-0.04002861,0.023101991,-0.012193609,-0.06188241,-0.014536828,-0.03764606,-0.031388298,-0.012552887,0.05153917,-0.038915556,-0.053771757,-0.06389494,0.017377168,0.047234867,-0.0019075165,-0.010570454,-0.0384987,-0.018860178,0.007972365,0.022238152,-0.02947865,-0.07742185,0.021430055,-0.01253248,-0.017709367,0.00735788,0.020728385,-0.018177217,0.04180225,0.042675126,-0.01363797,-0.12183665,0.016050216,-0.03700261,-0.03944924,0.04780061,0.030144665,0.05791682,-0.005092944,0.008627046,0.029964156,0.004444069,-0.022762662,-0.02391347,-0.057891045,-0.015942384,-0.02155307,0.014405616,0.01899066,0.03323191,0.019093174,-0.039946623,0.039963774,0.012686488,0.024126226,0.016293779,-0.05467434,0.03011379,-0.011070047,-0.03811539,0.027190454,0.013085346,-2.8104969e-05,0.021654576,0.010532401,0.06895435,-0.063621335,-0.044353858,0.061114304,-0.002293943,-0.0021902274,0.008072659,-0.0027576645,0.0023325176,-0.022892838,-0.000921341,-0.0920339,0.0038098118,-0.01517038,-0.019467063,0.023015678,0.016349537,0.03509545,0.015622487,0.019591633,-0.022601815,-0.04729633,0.005164391,0.0029284481,-0.010806898,0.009930674,-0.014289172,-0.059477814,0.004289986,0.02477377,-0.029374035,0.053021207,0.010042215,0.024961393,0.02575174,-0.0066923164,0.057428278,-0.013637515,-0.012463618,0.030921884]
4	invoice_time_entries	Table: invoice_time_entries\nDescription: junction table ที่ track ว่า time entry ใดถูกรวมใน invoice ใดแล้ว ป้องกัน double billing (time entry เดียวกัน invoice ได้แค่ครั้งเดียว)\nColumns:\n  id              UUID PRIMARY KEY,                                              -- รหัส\n  invoice_id      UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,       -- FK → invoices: invoice ที่ time entry ถูกรวมอยู่\n  time_entry_id   UUID NOT NULL UNIQUE REFERENCES time_entries(id) ON DELETE CASCADE, -- FK → time_entries: UNIQUE = 1 time entry invoice ได้แค่ครั้งเดียว\n  invoice_item_id UUID REFERENCES invoice_items(id) ON DELETE CASCADE,          -- FK → invoice_items: line item ที่ time entry นี้สังกัด\n  created_at      TIMESTAMPTZ NOT NULL   	[0.022434352,0.04498119,-0.02111152,0.027017329,0.017010355,-0.032466047,-0.020006524,-0.018014109,0.0315477,0.0070367353,0.0071908394,-0.008783998,0.10507569,0.051659215,-0.020832742,-0.022867817,0.005241824,-0.017207252,0.02927646,-0.012954144,0.06888452,-0.05872466,0.03975294,-0.024172643,0.00020546447,-0.010116461,-0.0014875606,0.013748638,-0.052455027,0.038437545,0.02835119,-0.020781683,-0.011410683,0.03641646,0.019214183,0.0020534345,-0.00809884,-0.0074437256,0.017882656,-0.0073870206,0.026686039,0.015306678,0.05147576,-0.023097996,0.03517697,-0.025691256,0.062616065,0.040609613,-0.017672794,-0.011223689,0.029621191,0.013918699,0.042922955,0.018610328,-0.05432101,-0.009801665,0.04334678,0.03168555,-0.03624348,-0.0011406364,0.017898373,0.04903127,-0.015395682,0.013930703,0.023253072,-0.013563901,-0.0006178136,-0.034857657,-0.04345276,-0.021731358,-0.0028872313,0.012273321,0.09011594,-0.019601341,-0.018365007,-0.010817714,-0.022555014,-0.0029812627,0.017438393,0.00406899,0.05854515,-0.0065746573,0.008355939,0.017391333,-0.008673636,-0.0039279694,-0.029285075,0.043838568,0.019789,0.026895873,0.03881087,-0.016103938,-0.032418363,0.011167893,0.038492672,0.030088937,-0.0011830196,0.0121179605,0.02861598,-0.02137029,-0.006068415,-0.08028417,-0.027245523,-0.02997252,-0.066000596,-0.033271734,-0.005302222,-0.037507847,0.07611531,-0.028811395,0.003486341,0.017342001,0.016295964,-0.05512338,0.04179486,-0.041257795,0.06862692,-0.086318426,0.026952365,-0.05634045,-0.06412336,-0.0049960306,-0.00028460776,-0.035268005,0.053376503,-0.014992798,0.012618116,-0.024790974,0.017087637,-0.051901884,-0.029659973,-0.06087475,0.01920736,0.0052904864,-0.022248209,0.020774828,0.030034993,0.021276442,-0.002825283,0.018238898,0.027974833,-0.023860257,0.0019253608,0.05053609,0.010131714,-0.07896268,-0.017636048,0.0048258235,-0.027908286,0.015312501,0.03698167,-0.06304689,-0.041018326,-0.00066749915,0.021822205,-0.012148663,-0.050798155,-0.013554851,-0.03080113,0.03274579,0.029348958,0.0026295139,0.021677619,-0.03206994,0.0607565,0.004825753,-0.0265823,0.032558765,-0.03300439,-0.00020085927,0.014828104,-0.052188322,-0.088951096,0.04528903,-0.006928058,-0.05167582,-0.018068064,-0.015861263,-0.02717361,-0.050898403,-0.07653509,-0.0028577547,-0.04672602,0.022251636,-0.0073873578,0.0025682484,-0.010218516,-0.034777783,0.035754047,-0.016929874,0.006953157,0.0890526,0.030824792,0.030138588,0.030731684,0.019115927,0.00798607,0.0022354675,0.010306328,-0.036857825,0.0007383473,-0.0030388546,0.036386937,0.028820252,0.010310992,-0.05226727,-0.00076413515,0.04719295,0.03968529,0.022567386,-0.037945695,0.033463452,-0.025012594,0.035473306,-0.033776313,-0.0391941,0.04306247,0.033389922,-0.03427838,0.022554146,-0.011860889,-0.044819303,0.04812469,0.04903205,-0.008242773,0.017745795,0.020013355,-0.015144588,0.025067147,0.004467412,0.058849324,0.091410525,-0.032174192,0.0070902365,-0.010062048,-0.010814947,0.03882398,-0.010725104,-0.016094176,-0.10538239,-0.039333183,0.027155908,0.015716745,-0.018706767,0.02921353,0.0017936788,-0.038865738,0.04604889,-0.02664768,0.00034523784,0.027910842,-0.05166284,0.0125094885,-0.03664982,0.013582584,-0.016179213,-0.030480985,0.0040484117,0.025719471,0.009013165,0.008305153,-0.026975151,0.004368921,-0.015841033,0.018246833,-0.02008064,0.021993749,-0.044177312,-0.026941236,-0.0026575392,0.013867837,-0.027929874,-0.0479211,0.0053743366,0.015451324,-0.0003148335,-0.05906839,0.012096629,-0.0016749313,-0.046733193,-0.029660853,0.02807639,-0.07190476,-0.039058328,-0.032416727,0.0035960306,-0.049223226,0.00489741,-0.055478137,0.009587873,0.0081492765,0.08064237,-0.019680725,0.0012378077,0.006860828,0.026127461,0.045993827,0.042283405,-0.0076809344,-0.0046645785,-0.014400347,-0.026920496,0.024852052,-0.0523737,-0.0323941,0.0203712,0.13264973,0.029614108,-0.043441165,0.050209843,-0.02589755,-0.008734757,-0.019269288,0.039139736,0.06729661,-0.053288348,-0.024612492,0.053996988,-0.0067253443,0.027710818,-0.03610623,0.037787415,-0.021033023,-0.07070813,0.029025001,-0.04382945,0.03515126,-0.021036988,0.06446392,0.024041235,-0.019151391,0.022626936,0.027656274,0.031932194,-0.06424137,0.02741842,-0.049227025,-0.05664368,0.05044917,0.030210664,-0.0086287,0.026443364,0.02940177,0.00018322065,0.0593455,-0.08722852,-0.028230924,-0.08620427,-0.048807286,0.009841388,0.018659249,-0.04694869,0.0034003372,-0.0055910386,-0.027375458,0.019131353,0.020391194,-0.010576346,-0.016332174,-0.0021797884,-0.0066076503,0.033788048,0.016387675,-0.009181961,0.0064971377,0.026797926,-0.06957105,-0.023847893,-0.014849217,0.016502574,0.14189336,0.03602458,-0.022990128,-0.0120982,0.02576724,-0.026352746,0.041115683,-0.07302524,-0.026338674,0.0060140523,0.027892515,0.025776664,0.018359654,0.036061753,-0.036828637,0.019445378,0.03257189,-0.027815482,0.015982911,-0.016156102,0.033229604,-0.0001356477,-0.0062344805,0.02783877,0.048011772,-0.03311829,-0.0037925018,-0.0075825956,0.0133363865,-0.041261103,0.059974637,0.0110848425,-0.01138999,0.055933774,0.04685715,0.01574171,0.0034778004,0.068013385,0.013490326,-0.05139927,0.043561097,-0.041196644,0.051233083,-0.017006237,-0.0061078835,-0.023827488,0.028119933,0.016613891,-8.3193896e-05,0.04505461,-0.075876474,0.032032553,0.020054542,-0.029557316,0.02917829,-0.10234356,-0.004730239,0.006590224,-0.0028131118,-0.0036185284,0.004097641,0.011514327,0.019358054,0.014146901,0.0075980364,-0.039754346,0.017936124,0.027679402,-0.0071059805,0.010403128,-0.0017462352,-0.011401138,0.02540452,-0.03422248,-0.020734271,-0.019820888,-0.06770985,0.020568056,-0.013731234,-0.004390321,0.01466278,0.007555824,0.028412344,-0.0103056785,0.029981136,-0.040156968,0.074802615,-0.013177372,0.012373427,-0.12507603,0.043497864,0.061453618,-0.0123828305,-0.023506107,-0.038166646,-0.07139411,0.011612343,-0.05624038,0.050847545,-0.016034864,-0.012191644,0.009450995,-0.038711634,0.06210042,0.015708275,0.04193589,-0.008248328,-0.0016330263,0.0347899,-0.0055105193,0.023607664,-0.012027663,-0.006200133,0.0073486585,0.0030703554,0.031261656,-0.1022362,0.03478323,0.030637503,-0.03639092,-0.04423473,0.03897507,0.040205166,-0.016940165,-0.032344993,0.031026177,-0.017146057,-0.032813538,0.05291771,0.03328312,-0.0188678,-0.039957862,-0.042856418,-0.006157728,-0.025202991,0.006656454,-0.023882123,0.03897165,0.04194222,-0.048548862,0.13024645,-0.010554846,-0.025833298,-0.0050467723,0.044716228,-0.005436351,-0.031188758,0.026827062,0.023225667,-0.023305066,-0.021870667,0.025669664,-0.034587055,-0.025729232,0.0021716482,-0.07661347,0.022742093,-0.05111337,0.03113568,0.00085233385,0.014912119,-0.022626055,0.043809373,-0.07509471,-0.052434683,0.055292763,-0.008847818,-0.017422954,0.035671506,-0.019338792,0.017259488,-0.024850743,0.037665598,-0.03098525,0.034709714,-0.04868867,-0.010457046,-0.021308692,0.0032856038,-0.0028539232,0.05483226,-0.013024656,-0.022747628,0.049503982,-0.013071282,0.043914568,0.036452614,0.019589,0.0036188324,-0.01566951,-0.009352436,-0.027275397,0.0061922343,0.015198092,0.03424127,-0.012818241,0.02761371,-0.017689383,-0.009238468,0.038562745,-0.0620134,0.038501102,0.037345577,0.010136794,0.03597032,0.0024694034,-0.020662012,-0.020379981,0.0068809087,-0.07422721,-0.04759124,-0.024054825,0.0066849864,0.023674525,0.053446013,0.014091607,0.032462746,0.030165007,-0.20095013,0.0013866413,-0.011927443,-0.03887514,-0.002436515,0.043550216,0.024557663,-0.018710062,0.006839956,0.0026376292,0.04942669,-0.023366055,0.0052859983,-0.03368241,-0.035727873,0.050041452,-0.0072833076,-0.038406644,0.026628356,0.04867646,0.0032297827,0.09468881,-0.022453174,-0.00840088,-0.0547659,-0.05526005,-0.014974852,0.035491515,0.017577555,-0.0017811308,0.0151757775,-0.011940748,0.017208382,-0.0057410495,-0.014572446,-0.022061137,-0.011532474,0.014162412,-0.09725267,0.06755684,0.014536228,0.0019919572,-0.054074258,0.005434432,-0.006565546,0.058647715,0.030996276,0.037445784,-0.043138713,-0.030347234,0.0030256205,-0.0016187095,-0.08278363,0.022014143,0.005304536,0.044372533,0.03878994,-0.0016407216,0.056328204,-0.019510914,0.044669703,0.0362372,-0.05298143,-0.017801026,-0.011128041,-2.1627935e-05,0.045017127,-0.03489693,-0.008949094,0.009179938,0.032674424,-0.028122444,-0.031440705,0.011021567,0.03057547,-0.043547656,0.022850137,-0.020827694,-0.08800966,-0.007101667,-0.013505704,-0.026204528,-0.017015252,0.040886406,-0.031877622,-0.03598054,-0.04825541,0.022509446,0.028374491,0.018714042,-0.015303626,-0.025839707,-0.008488623,-0.013380959,0.016300602,-0.031439845,-0.049821787,0.042733517,0.02242524,-0.0043018674,0.02169442,-0.0061519025,-0.028192893,0.0060114893,0.035302937,-0.023040844,-0.119992375,0.018893713,-0.034492273,-0.03103976,0.04392623,0.034970615,0.026881505,-0.011822208,0.0153591875,0.010971222,0.0023544529,-0.021362599,-0.02357994,-0.05097116,-0.015068749,-0.014229223,0.002387527,-0.003585725,0.039950702,0.013560465,-0.048609916,0.048253078,0.0029207761,0.036924772,0.017128285,-0.03956968,0.025563866,-0.015227005,-0.011415671,0.020845309,0.017408052,0.0028252772,0.02730679,0.005053714,0.06404241,-0.080173165,-0.031549707,0.049638696,0.014340559,-0.024493443,-0.006201332,0.004821704,-0.0067172498,-0.026131896,-0.008826676,-0.08508824,0.019220253,-0.012714387,-0.024750413,0.031214582,0.024943609,0.046535958,0.010083564,0.012649103,-0.0084912125,-0.04003799,0.008283213,0.015043851,0.011474552,0.02794088,-0.022496417,-0.058526676,0.0155951865,0.010244021,-0.043275226,0.054236125,0.009596323,0.00831243,0.022620432,-0.026585769,0.053834233,-0.0026571923,-0.031548116,0.020189086]
5	invoices	Table: invoices\nDescription: ใบแจ้งหนี้ที่ออกให้ client แต่ละใบมี status, วันที่, และยอดเงินรวม invoice ที่ status='sent' และ due_date < วันปัจจุบัน ถือว่า overdue\nColumns:\n  id              UUID PRIMARY KEY,                                      -- รหัส invoice\n  team_id         UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,   -- FK → teams\n  client_id       UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE, -- FK → clients: client ที่ออก invoice ให้\n  invoice_number  VARCHAR(50) NOT NULL UNIQUE,                           -- เลขที่ invoice เช่น INV-2025-001 ต้อง unique ทั้งระบบ\n  status          VARCHAR(20) NOT NULL DEFAULT 'draft',                  -- สถานะ: draft (ร่าง) / sent (ส่งแล้ว รอจ่าย) / paid (จ่ายแล้ว) / cancelled (ยกเลิก)\n  issued_date     DATE NOT NULL,                                         -- วันที่ออก invoice\n  due_date        DATE NOT NULL,                                         -- วันครบกำหนดชำระ (status='sent' และ due_date < today = overdue)\n  subtotal_cents  INTEGER NOT NULL DEFAULT 0,                            -- ยอดรวมก่อนภาษี หน่วยสตางค์\n  tax_rate_percent NUMERIC(5,2) NOT NULL DEFAULT 0,                      -- อัตราภาษีเป็นเปอร์เซ็นต์ เช่น 7.00 = VAT 7%\n  tax_amount_cents INTEGER NOT NULL DEFAULT 0,                           -- จำนวนเงินภาษี หน่วยสตางค์\n  total_cents     INTEGER NOT NULL DEFAULT 0,                            -- ยอดรวมทั้งหมด = subtotal_cents + tax_amount_cents (หาร 100 ได้หน่วยเงินหลัก)\n  notes           TEXT   	[0.015892906,0.040916923,-0.015912632,0.020854859,-0.008374162,-0.030764084,-0.027038226,-0.0003346354,0.019003835,0.0022529238,0.03267007,0.002977966,0.100337416,0.057052597,-0.025484411,-0.03578011,0.014054034,-0.010297697,0.019744046,-0.014191766,0.031772923,-0.049958978,0.023959646,-0.008585146,0.02589958,-0.027042625,-0.004687366,-0.008775005,-0.05330996,0.0556661,0.040788088,0.008867992,0.0022709211,0.03677852,0.013166518,0.018002097,-0.024130045,-0.040435083,0.0048256675,0.0008990054,0.026803207,-0.0053035975,0.05104111,-0.01873234,0.027798006,-0.032303553,0.062485714,0.015179066,-0.026488628,-0.0075534172,0.039896596,0.0044246274,0.049536023,0.01922896,-0.04035372,-0.008351966,0.02611656,0.034387626,-0.024416827,-0.0060231923,0.019232834,0.04702296,-0.009403738,0.031797063,0.025936069,-0.011208006,0.015282313,-0.038049147,-0.046567716,-0.025982838,-0.0022716452,0.028350545,0.11251958,-0.023697479,-0.026378796,-0.0036686454,-0.02708319,-0.003682123,-0.005609017,-0.009944155,0.05177065,0.0087946225,-0.0027870655,0.030576296,-0.0003550902,0.003150452,-0.020925347,0.03669465,0.0206473,0.039851308,0.015852708,-0.025835913,-0.057219863,0.015441299,0.026588073,0.03340489,0.013684189,0.008297615,0.04251138,-0.027886821,0.0039827176,-0.076868415,-0.0050278665,-0.02273561,-0.0768152,-0.011667236,-0.0028069357,-0.032020792,0.05837569,-0.030582312,-0.042406622,0.017769154,0.022569345,-0.05294756,0.033373907,-0.03651808,0.059903696,-0.054836195,0.010177751,-0.08074819,-0.029672928,0.008341778,-0.0035152491,-0.019815534,0.037407268,-0.02773371,-0.0062837596,0.0050511574,0.031942934,-0.06419537,-0.041558262,-0.043354485,0.006435226,0.032546457,-0.0011094749,0.03566624,0.021907734,0.010893138,-0.011631382,0.00372734,0.020147335,-0.022991884,0.018265912,0.04652806,-0.0065736463,-0.052742563,-0.011455804,0.0102493875,-0.032652188,0.026377669,0.021952642,-0.06796037,-0.041627463,0.0022173808,0.030338189,0.0025841654,-0.023555553,-0.01809121,-0.0070904535,0.021216484,0.028670894,-0.0139363725,-0.0021591028,-0.03830452,0.06576943,0.009184464,-0.0067250594,0.028049111,-0.042771123,-0.00212851,0.01858382,-0.031170903,-0.06890155,0.041879836,-0.0030529068,-0.0337469,-0.03157412,-0.023379546,-0.027832275,-0.058343336,-0.0636126,0.010061546,-0.01904709,0.022620663,-0.019035071,-0.0036522762,-0.035959024,-0.018031154,0.07162291,-0.010880867,-0.0026754588,0.08566868,0.0016719403,0.023013212,0.035194915,0.011906383,0.026741289,0.003584876,-0.028515676,-0.04738871,0.016527288,-0.011156041,0.059538566,0.06293908,0.0077191535,-0.05265443,0.002399305,0.030796079,0.0027304909,0.022883765,-0.026657516,0.026090145,-0.045118395,0.038982153,-0.019504301,-0.047926042,0.034600414,0.023917943,-0.023728915,0.047694456,-0.0005353071,-0.06272594,0.057965398,0.042845994,-0.023646425,0.022102619,0.008772093,-0.03504475,0.021720286,0.016620826,0.05588539,0.10232734,-0.02473873,0.026472434,0.00028807612,0.0017324011,0.042881005,-0.0042740614,-0.017821006,-0.09843283,-0.051253002,0.0017652329,-0.0008847027,-0.011513048,0.027067874,-0.014853393,-0.06136122,0.056445185,-0.06163693,0.02212122,0.043073364,-0.058020454,0.01666857,-0.033468693,0.014071087,-0.0023137752,-0.05117722,0.022088647,0.029683683,-0.0040466716,-0.004115876,-0.010612649,0.012514017,-0.009131929,0.0036706165,-0.025041474,-0.00039987057,-0.038784396,-0.029008476,-0.007070734,0.008851965,-0.032618128,-0.034827903,0.00823424,0.014530377,-0.009872396,-0.050891254,0.009667156,0.004712048,-0.06753841,0.005615121,0.04988174,-0.05989109,-0.017912174,-0.038096797,0.0017616476,-0.05286988,0.011045568,-0.03975836,-0.010949973,0.025366776,0.102431856,-0.0012531504,0.014781516,0.029727219,0.01943542,0.016736425,-0.0040852614,0.008361407,0.0007047661,-0.011039522,-0.030722467,0.01079679,-0.060965236,-0.03062971,0.030834524,0.1286664,0.021783656,-0.036625504,0.051540315,-0.017782493,0.00083194213,0.001081507,0.03996384,0.038416587,-0.052496053,0.033872552,0.05492917,-0.018959247,0.028649354,-0.014167893,0.034432996,-0.03543742,-0.06538668,0.036704514,-0.024962703,0.032816727,-0.009129062,0.05758167,0.0144979255,-0.025140045,0.02421934,0.016332122,0.016485255,-0.07169208,0.030415652,-0.08955707,-0.045661032,0.06787844,0.026871169,-0.038677875,0.039422393,0.023398677,-0.015983893,0.033159096,-0.09845477,-0.015758649,-0.07577734,-0.051716127,0.0035800866,0.0053771236,-0.06301235,0.012765591,-0.007542136,-0.028145632,-0.0031421487,0.019229922,-0.021529494,-0.03595015,-0.021091755,-0.0050349315,0.029778212,0.03343125,-0.012685812,0.019107513,0.02246863,-0.076423645,-0.031824537,0.013618028,0.017121414,0.08784695,0.051508322,-0.025053317,-0.026627796,0.049760718,-0.022937853,0.010659619,-0.06544608,-0.021849804,0.0041097943,0.03435008,0.02789829,0.034202024,0.04046955,-0.050263274,-0.0013083488,0.019147139,-0.05913544,0.042023923,-0.02208003,0.0389157,-0.0116606755,-0.017564833,0.03834671,0.047249563,-0.035055682,-0.023781106,-0.002666792,0.020571781,-0.035884198,0.05027859,0.0068160263,-0.019277517,0.05660522,0.048721664,0.04174575,-0.033690013,0.03665053,0.040862955,-0.03561326,0.03970698,-0.04860908,0.046144906,-0.017067362,0.01323537,-0.007605951,0.01849372,0.04855785,-0.004935417,0.026748806,-0.05280505,0.022838082,0.013981571,-0.013815125,0.03172498,-0.07035933,-0.0059682764,-0.009075849,-0.0033287096,0.0099391015,-0.008421352,0.009755377,0.0017786906,0.0016325428,0.0043011615,-0.046677027,-0.0051333583,0.043228365,-0.016845476,0.00562451,-0.027759865,-0.016587274,0.014884418,-0.021868963,-0.023858953,-0.013875211,-0.039598577,0.012029806,-0.02135015,0.0017145852,-0.010713481,-0.00025429713,0.026553266,-0.008486206,0.032912526,-0.05714522,0.07565009,0.00966179,0.017886838,-0.116722584,0.04426476,0.02555654,-0.0034807213,0.0063955174,-0.039245937,-0.06572012,-0.0024835547,-0.025426975,0.052717835,0.003413893,-0.019133197,-0.022083096,-0.011035943,0.051503815,0.012867001,0.054189883,-0.012436628,0.008202953,0.029451331,0.004108745,0.026481248,0.00031823196,-0.013719898,0.016653921,0.008817913,0.03418576,-0.10552323,0.034115337,0.06691717,-0.049730293,-0.027504697,0.01297597,0.04038705,-0.022201678,-0.020060299,0.053899,-0.005320576,-0.056921106,0.03858917,0.033956394,-0.028649725,-0.022822568,-0.029680852,0.006718599,-0.027362287,0.017003117,-0.0076665166,0.030528225,0.033321977,-0.043203235,0.13584322,-0.017554093,-0.029482672,-0.013262317,0.0035626756,-0.0027674565,-0.02002632,0.022805152,0.009228665,-0.015374271,-0.043655492,0.015839854,-0.029267376,-0.04464135,0.04494401,-0.03817456,0.0008312393,-0.048535544,0.049443115,-0.00043342626,0.02254703,-0.026236389,0.016918423,-0.11933334,-0.07609141,0.020476338,-0.012146696,-0.030136589,0.040115997,-0.032191522,0.0014745626,-0.022105396,0.048582397,-0.018331489,0.013170503,-0.048340008,-0.0012057741,-0.025779285,-0.026332889,-0.021624489,0.05723489,-0.008546983,-0.029461432,0.04362558,-0.0016324581,0.04849524,0.020796277,0.012374764,0.0122345155,-0.04641097,0.022133827,-0.025604814,-0.009833752,0.037701614,0.02509393,-0.018053154,0.03609754,-0.025025718,-0.019333608,0.056488875,-0.048201766,0.02946409,0.019604541,-0.012317031,0.018806916,0.035175588,-0.009754696,-0.03415262,0.025935557,-0.063830934,-0.024084281,0.0036140892,0.015458952,0.028803915,0.054943755,-0.007863479,0.03647865,0.01144659,-0.21125792,0.0034868026,-0.025704417,-0.057709426,-0.0076026153,0.03562312,0.03244058,-0.050902516,0.007968059,0.018345388,0.044661246,-0.019546188,0.026059784,-0.046183906,-0.036243517,0.013497651,-0.011787424,-0.02370923,0.022291657,0.030491207,-0.016194277,0.07819772,-0.021960927,-0.011295758,-0.05024124,-0.030342957,-0.026679944,0.023529679,0.012171198,0.023118164,0.026419388,-0.01255851,0.01789284,0.011541425,-0.0022707134,-0.008437204,-0.009813591,-0.002233208,-0.103344075,0.04100203,0.016435128,-0.010062724,-0.030353231,0.012554523,0.0029606486,0.03119137,0.010218446,0.048470028,-0.040596757,-0.017274227,0.012409081,0.018390002,-0.10011401,0.025951266,-0.009754442,0.048763357,0.032362856,0.020319734,0.054146405,-0.027107548,0.06887615,0.05756708,-0.0401177,0.002926606,0.0033446338,0.03531796,0.016694384,-0.029638147,0.008771745,0.03822444,0.032665785,-0.04081094,-0.012356435,0.008164224,0.045145392,-0.041647438,0.03606168,-0.029276771,-0.06537459,-0.0022783375,-0.056692474,-0.029663486,-0.0035739539,0.030685725,-0.024744233,-0.03377609,-0.05688426,0.01885734,0.03641741,0.01936435,-0.023508672,-0.022428758,-0.0053811483,0.0070978813,0.018849904,0.000626189,-0.06596654,0.013845118,0.008609941,-0.024010211,0.030303959,-0.010143473,-0.01553921,0.018754482,0.03231537,-0.030723672,-0.13092493,0.031819485,-0.03789097,-0.052876238,0.05252945,0.038239617,0.05285407,-0.0059748334,0.00085543835,0.007985996,0.016512638,-0.027329775,-0.02488133,-0.06666341,-0.0045408444,-0.01794763,0.01729479,0.030266535,0.0479857,0.017485978,-0.031258926,0.039567165,0.02783873,0.02205273,0.0006711967,-0.03427215,0.012290574,-0.025757609,-0.032991283,0.022624657,0.01745338,-0.003395904,0.02153449,0.013928994,0.06477274,-0.058888745,-0.035325192,0.04951276,0.0025078857,-0.00236574,-0.0034831658,-0.01321332,0.013987969,-0.009586599,-0.020204362,-0.07309,0.024381362,-0.014887355,-0.002840493,0.04029504,0.03848339,0.03252217,0.033919916,0.028211195,-0.022763522,-0.043145586,0.00171846,-0.00078202976,0.002813334,0.01989685,-0.005843663,-0.047305007,-0.00789062,0.021326676,-0.032781124,0.071800694,0.03444558,0.011075371,0.02350119,0.0072564054,0.04404451,-0.027028982,-0.0378303,0.02215605]
6	migrations	Table: migrations\nDescription: system table สำหรับ track การ migrate database schema ไม่ใช่ business data ใช้ภายในระบบเท่านั้น ไม่ควรนำมาใช้ใน business query\nColumns:\n  id          SERIAL PRIMARY KEY,       -- รหัส migration ลำดับอัตโนมัติ\n  name        VARCHAR(255) NOT NULL UNIQUE, -- ชื่อไฟล์ migration เช่น "001_create_teams_table"\n  executed_at TIMESTAMPTZ NOT NULL DEFAULT NOW() -- วันเวลาที่ migration นี้ถูก run	[0.019901915,0.03272279,-0.020593653,0.009068414,0.0129557345,-0.044704564,-0.011396431,-0.040020104,0.04953053,0.031522475,0.02752181,0.025980813,0.12216814,0.030381406,-0.022083247,-0.030761184,-0.022743655,-0.028479816,0.011248237,-0.014778405,0.040548343,-0.028262518,0.0018442493,-0.015873097,0.0018030423,-0.03434987,0.0006722508,0.0011583125,-0.037407055,0.021412235,0.0016340681,-0.02464852,-0.010550568,0.025971174,0.018323677,-0.0047440506,-0.028768947,-0.012721892,-0.008766794,0.016851416,0.033115145,0.009287779,0.04757397,-0.027277801,-0.00025123951,-0.01323471,0.04889694,0.00027921476,-0.019912668,0.0009361215,0.034884628,0.02596409,0.048101045,0.04100636,-0.0331454,-0.019162372,0.036578886,0.029119078,-0.04852661,0.009387377,-0.015044584,0.03404133,-0.0145943435,0.014018123,0.03936675,-0.041399546,-0.005914154,-0.03220583,-0.055166453,-0.017904142,-0.0061030006,0.010318478,0.11553255,0.006538942,-0.0038294047,-0.0051624603,-0.04096163,0.015810477,0.0019908089,0.0008031142,0.04553612,0.02077852,0.020286208,0.034787614,-0.010898939,-0.0062586656,-0.017913895,0.024592979,0.031047003,0.052733626,0.015484981,-0.037550732,-0.04066187,0.05029565,0.013056702,0.03255419,0.0019167379,-0.00043703947,0.04141749,-0.059285894,-0.018707288,-0.09607614,0.0009461134,-0.049303632,-0.076727465,-0.02842198,2.604012e-05,-0.052730236,0.07171598,0.0069237663,-0.022652695,0.041302238,0.016579809,-0.053296003,0.017724046,-0.056651797,0.040079575,-0.03964233,0.012875339,-0.05855165,-0.023891004,0.03773619,-0.00097554084,0.0003284973,0.04577587,-0.06680411,0.002367258,-0.014315713,0.051458757,-0.034022477,-0.03559284,-0.019899338,0.02844136,0.00090221514,0.0031677438,0.058412034,0.024534458,0.0023392835,-0.013902897,-0.008164889,0.037350226,-0.043005195,0.0034057614,0.061181106,0.0012725231,-0.061553195,-0.016885696,0.018001238,-0.025181666,0.017028423,0.027095992,-0.038539167,-0.027059712,-0.018266574,0.03175404,0.0036620842,-0.04354931,-0.008791091,0.0121495435,0.0228099,0.025282621,-0.014368498,0.004809986,-0.04177455,0.026445676,7.024186e-05,-0.03717193,0.0030573497,-0.061828144,-0.0083029615,0.017772123,-0.06356302,-0.07313147,0.043691993,-0.02622103,-0.03338872,-0.010769819,-0.034619875,-0.029593008,-0.03760147,-0.06580214,-0.0018618956,-0.044325344,0.021837194,-0.0010845846,-0.022901203,-0.039958157,-0.041581135,0.0345216,0.007526537,-0.0013685353,0.07550889,0.01889451,0.03632904,0.0057344693,0.023140704,0.021138202,0.0196111,0.008324537,-0.046788145,0.008982897,-0.00968173,0.036637783,0.021368751,0.013803095,-0.07970438,-0.016628677,0.068255566,0.032808587,0.01175355,-0.019688984,0.036538895,-0.014959937,0.02441261,0.0009068753,-0.048197865,0.034683987,0.01641247,-0.019935224,0.053451583,0.004943091,-0.046054397,0.08420028,0.03969319,-0.030738015,0.00014917165,0.010227251,-0.038316824,0.03828045,0.043085966,0.04286687,0.08688475,-0.022127772,0.0454233,0.00015006965,-0.033933904,0.06635693,-0.020588387,-0.006843328,-0.10543448,-0.031213673,0.010706518,0.0025319436,-0.028418602,-0.004946155,0.005098169,-0.039820626,0.021871896,-0.045061532,0.021977134,0.031826925,-0.0336556,0.016498165,-0.031857174,0.021774821,-0.0031362695,-0.018400665,-0.024417782,0.05501628,-0.013590204,0.016855966,-0.029426433,0.01861567,-0.047966726,0.009733335,0.007041936,0.011708346,-0.012568044,-0.046441823,-0.004627088,0.020912522,-0.017965484,-0.037084445,0.018213203,0.02210372,-0.002567454,-0.058774,0.014133887,-0.005437683,-0.06299012,-0.06820741,0.024774548,-0.04541872,-0.0074686976,-0.018211035,0.009267531,-0.03893523,0.010811493,-0.04065031,-0.01577117,0.002840102,0.07222561,-0.020645903,-0.0123497965,0.032592162,0.016369076,0.032867555,-0.0033048452,-0.032675836,-0.016269,-0.024184033,-0.009138068,0.043702804,-0.074121855,-0.018263148,0.040687077,0.10184312,-0.009310899,-0.036683805,0.03451506,-0.010920985,-0.019538704,-0.043034278,0.061197963,0.059757326,-0.057714287,0.005954715,0.06531099,-0.005769209,0.02080313,-0.057978235,0.020091042,-0.0016734818,-0.063706994,0.030180836,-0.03280516,0.04237832,-0.0008072735,0.012534527,0.018542467,-0.043059465,0.029613825,0.0042179497,0.0302915,-0.0400437,0.013395565,-0.031826936,-0.060080085,0.08003332,0.038516488,-0.0042533726,0.059086382,0.019798798,-0.009994861,0.090161346,-0.0753818,-0.017731633,-0.055586755,-0.04844947,0.022951312,0.033664197,-0.060211517,0.018735457,-0.0100915935,-0.0344423,-0.0050577084,0.019500295,0.015251578,-0.029139541,-0.0013655573,-0.011196056,0.029381448,-0.0018559649,-0.0019183323,0.023283085,0.023171574,-0.06364579,-0.015030175,0.0023196854,0.016473878,0.09826826,0.02361164,-0.041354,-0.012316682,0.05615452,-0.020329004,0.013767335,-0.06658372,0.0037264817,0.008075609,0.036735613,0.070680164,0.013013802,0.027540028,-0.039517455,-0.0040845894,0.0098901475,-0.074084856,0.039325748,-0.028866956,0.047767736,0.011976881,-0.0101150405,0.044507675,0.050367862,-0.027200755,0.032731973,0.0022577147,0.017676635,-0.0446269,0.050628126,0.045749802,-0.005947797,0.057514902,0.0450356,0.043843262,-0.022906577,0.04559978,0.028586851,-0.0097495075,0.03578182,-0.024570817,0.032311466,-0.00055814214,-0.0036178736,-0.021447927,-0.008037106,0.048625026,0.011342547,0.012082755,-0.07967281,0.042812314,0.033740014,0.0031448063,0.024588138,-0.10471692,0.014730103,-0.024994222,-0.018299505,-0.009363473,-0.014054099,-0.004262564,0.026715836,-0.018761741,0.017796228,-0.05186137,0.027427524,0.032146674,-0.039208323,0.0017122419,0.018686708,-0.030906703,0.02925983,-0.041464955,-0.007919817,-0.0066755037,-0.025984913,0.0051591815,-0.036375333,-0.004934776,-0.010027619,-0.040239245,0.0072879144,-0.008806776,0.041429657,-0.0379534,0.05755681,-0.02653151,0.02001909,-0.115851074,0.04402216,0.037467916,-0.0040469794,-0.0004442554,-0.017124632,-0.0724696,0.03823055,-0.062334973,0.025860451,-0.027362896,-0.06736024,-0.02799757,0.02233315,0.025398158,-0.00924887,0.048018623,0.029517258,0.027858572,0.006630046,-0.007921109,0.02519234,-0.014171572,-0.013070273,0.01543309,0.018277595,0.029500328,-0.08642772,0.04140634,0.043370187,-0.037717536,-0.042081736,0.036684815,0.03577615,0.003052918,-0.0006675539,0.035005197,-0.0070431335,-0.055006832,0.02188843,0.044024747,0.0017058817,-0.036607556,-0.028355831,-0.00081479194,-0.021099221,-0.0039099506,-0.0575901,0.046164103,0.03556441,-0.041453414,0.10387525,-0.033755478,-0.0031621128,-0.010771886,0.038938817,0.0074186656,-0.021545008,0.029937685,0.010690568,-0.017303828,-0.020075401,0.014876805,-0.050982572,-0.018676082,0.0067195124,-0.040416703,-0.0031616811,-0.044414707,0.055633605,-0.041181047,0.031980783,-0.022292366,0.052905165,-0.09608443,-0.0428235,0.016825683,0.011105345,-0.020534724,0.05291093,-0.020634884,0.031769946,-0.007552899,0.01143679,-0.04393674,0.00046948396,-0.024645088,0.01743026,-0.026753962,-0.010251784,0.015876412,0.042202555,-0.014642623,-0.008221565,0.053947017,-0.01873172,0.05361471,0.007570018,0.044242356,0.019665986,-0.044233937,0.0050311713,-0.009840422,-0.013057357,0.016957613,-0.012306676,0.018350031,0.006921131,-0.023010856,0.010462584,0.050964873,-0.054970738,0.023923406,0.01848456,-0.0012349306,0.034815002,0.040446866,-0.0048904973,-0.0065296995,0.0056918324,-0.083516024,-0.04841139,-0.036418565,0.011146628,0.020429062,0.04933273,0.0010049468,0.007889419,0.041596375,-0.21053068,0.01604954,-0.055967685,-0.03227709,0.015797224,0.056263622,0.036592778,-0.023723353,-0.0071651833,0.037341416,0.03940979,-0.04090492,0.028763106,6.445656e-05,-0.033964437,0.021048786,-0.024305731,-0.015962431,0.014253591,-4.4090462e-05,0.0145762665,0.05357598,-0.04904774,0.0025828495,-0.055114485,0.0074176337,-0.029702917,0.026463412,0.027182885,-0.00044372084,0.018154623,0.013987894,0.041169588,0.027784359,-0.013152839,-0.021650648,-0.022437748,0.00927821,-0.06224912,0.043197215,0.008571655,-0.008552547,-0.029517516,0.027625704,-0.008564296,0.042508505,0.023802122,0.026082277,-0.030358098,0.012129512,0.013977423,0.00012809993,-0.11067262,0.0033492662,-0.007297099,0.06284418,0.022502711,0.0023317137,0.02859597,-9.879679e-05,0.049487717,0.06815687,-0.023674605,0.00039493557,0.010529397,0.013226062,0.06615377,-0.048749536,-0.028943283,0.012685305,0.02681859,-0.032840572,0.003721267,-0.00627184,0.021726884,-0.02824599,0.011268867,-0.02918481,-0.05102301,0.02768243,-0.046351828,-0.008448353,-0.018404238,0.022903975,-0.045571703,-0.022222107,-0.059960842,0.010027288,0.043053586,0.005512541,-0.021553356,-0.05345024,-0.030747732,0.0239773,0.024897177,-0.011519173,-0.021506794,0.022793831,-0.039342932,-0.014781911,0.014740435,-0.012988294,-0.01822172,0.025817903,0.052526865,-0.074371375,-0.10431037,0.026789648,-0.020078199,-0.05955633,0.074092224,0.031380754,0.05453362,-0.012372311,0.029662177,-0.0032261533,0.039156705,-0.048304535,-0.037760474,-0.044006273,-0.010427905,-0.015467919,0.0052007935,0.0049540885,0.04023002,0.022266963,-0.044904508,0.035053574,0.019366646,0.031435188,-0.004843784,-0.054326545,0.03943233,-0.020976815,-0.0072955997,0.037535787,0.023159826,-0.028230133,0.023894351,0.03309016,0.066049114,-0.056584433,-0.029974736,0.049422473,-0.010232295,0.048343506,0.021481518,0.0062929457,-0.006297242,-0.030635098,0.006132437,-0.106627345,0.013555276,-0.018851869,-0.031558942,-0.01231794,0.028354228,0.016300775,0.01184197,0.02328168,-0.01291656,-0.048205245,0.00869013,0.02241664,0.0074426546,0.028240157,-0.03538364,-0.01834584,0.008741534,0.02453406,-0.007504749,0.038928796,0.013118207,0.0046017426,0.010370473,-0.015204047,0.056274682,0.006981142,-0.0047236164,0.03455167]
13	teams	Table: teams\nDescription: หน่วยองค์กรหลัก ข้อมูลทั้งหมดในระบบผูกกับ team เสมอ user คนหนึ่งสามารถอยู่ได้หลาย team\nColumns:\n  id              UUID PRIMARY KEY,     -- รหัส team สร้างอัตโนมัติ\n  name            TEXT NOT NULL,        -- ชื่อ team ความยาว 2-120 ตัวอักษร\n  slug            TEXT NOT NULL UNIQUE, -- URL-friendly name เช่น "crafted-studio" ต้อง unique\n  billing_address JSONB,               -- ที่อยู่สำหรับออก invoice เก็บเป็น JSON (street, city, country, postal_code)\n  created_at      TIMESTAMPTZ NOT NULL, -- วันเวลาที่สร้าง team\n  updated_at      TIMESTAMPTZ NOT NULL  -- วันเวลาที่แก้ไขล่าสุด อัปเดตอัตโนมัติผ่าน trigger\n	[0.011709116,0.031242883,-0.03452838,0.0050755464,0.014738265,-0.022411954,-0.02239416,-0.032089215,0.05464894,0.0028095746,0.013461214,-0.0010805264,0.10852789,0.043552563,-0.006213523,-0.021188118,0.0017103188,0.004062398,0.008874686,-0.015528102,0.045324076,-0.050594863,0.02749742,-0.016343892,0.021066131,-0.015758112,0.013402666,-0.014457647,-0.055537447,0.027569555,0.028501935,-0.023144687,-0.0073734215,0.025692323,0.02296043,-0.002589956,-0.0022603623,-0.0051935078,-0.0069688056,-0.016312359,0.038092088,0.0063044224,0.043604262,-0.016360313,0.02155152,-0.02058425,0.05311276,0.0022442974,-0.030847233,0.004620588,0.031375803,0.010921312,0.04011971,0.008273787,-0.05230261,-0.022805737,0.023598848,0.031859066,-0.03491661,0.013800937,0.001705,0.04319456,-0.015010527,0.042102758,0.016905827,-0.03368687,0.013480182,-0.03134519,-0.04125636,-0.02036411,-0.013385983,0.018533425,0.11088733,-0.0071989517,-0.054976583,-0.005720531,-0.05581776,0.010097674,-0.014130353,0.04263306,0.065297715,-0.0022055528,0.01924789,0.02722088,-0.01741927,-0.008810262,-0.029437108,0.04687368,0.05441122,0.063278615,0.008958202,-0.04526185,-0.040326376,0.020832948,0.015048154,0.03423719,-0.0059384364,-0.0029352948,0.060497362,-0.022040982,-0.017022394,-0.09308038,0.0049603125,-0.03359826,-0.08174298,-0.03192661,-0.004404339,-0.049071994,0.044046145,-0.028815698,-0.006956779,0.0043509123,0.0044585997,-0.068674535,0.044337083,-0.069788024,0.032690812,-0.045389213,-0.00090955675,-0.067909524,-0.04793243,0.017743105,0.0037338706,-0.016428208,0.057340935,-0.03912386,-0.011525493,-0.007272248,0.025523301,-0.052531566,-0.046239484,-0.023556374,0.024867572,0.012966605,-0.0045444383,0.042462908,0.013621159,0.002039924,-0.031186558,-0.0005460386,0.053080168,-0.031331632,0.009446315,0.050820746,0.015734814,-0.04860412,-0.0058465777,0.011669721,-0.019210761,0.011635863,0.04762099,-0.049113832,-0.03233684,-0.007325019,0.007550114,0.008577185,-0.047479603,-0.010741182,0.0367752,0.04199804,0.033060927,-0.008947438,0.001762736,-0.033571206,0.039670285,0.013358532,-0.024153609,0.013487855,-0.034315452,-0.03385568,0.012186358,-0.056135748,-0.11125081,0.047709554,-0.027852125,-0.027257686,-0.010481021,-0.042799525,-0.027801462,-0.040115595,-0.06264029,0.006728593,-0.016855283,0.02271516,-0.012542538,-0.0017430101,-0.022221547,-0.037976805,0.051886316,0.0023885916,-0.0070560104,0.10276808,-0.006317404,0.04372982,0.00065750064,-0.008486393,0.036219217,0.02493848,-0.0010615643,-0.053390775,0.0099194255,-0.012586662,0.024235167,0.04623193,0.023804773,-0.06472244,-0.004571507,0.03263838,0.015417429,0.011748807,-0.03441096,0.03418459,-0.011970376,0.025639987,-0.01209182,-0.044241082,0.031465247,0.020329487,-0.010097286,0.057932697,-0.0031575083,-0.042739183,0.06084469,0.031976636,-0.018609378,0.019498821,0.021218352,-0.022136495,0.016387245,0.037202213,0.042104512,0.09743888,-0.023800576,0.04303426,-0.0013052397,-0.010604748,0.04839236,-0.009208565,-0.0061616814,-0.09705139,-0.04338582,0.011162273,0.020861562,-0.022018656,0.018131008,-0.012376961,-0.042971123,0.0305577,-0.03232445,0.011749931,0.044840816,-0.048488114,0.004149815,-0.015028373,0.03279935,0.0066640954,-0.04401898,0.012763162,0.035390656,0.0006531941,0.0037560598,-0.009046053,0.013455879,-0.03353523,0.020312995,0.010778361,0.012544594,-0.009776676,-0.060788434,0.013063238,0.036799118,-0.0199502,-0.028012821,0.01619393,0.015724983,-0.018118452,-0.05948285,0.009228367,-0.006100181,-0.06169362,-0.013773795,0.05296381,-0.062371142,-0.037323095,-0.03559087,-0.009437554,-0.04539937,-0.0024255933,-0.027303856,0.0160657,0.012265815,0.07906861,-0.0027077706,0.0037413964,0.046113178,0.033179905,0.04222878,0.0061206734,-0.03180496,0.01736742,-0.026298825,-0.027459586,0.026548183,-0.08466123,-0.007833077,0.031253293,0.11446079,-0.0062130974,-0.03403399,0.030350229,-0.019743642,-0.00046509295,-0.01901377,0.05280334,0.03203989,-0.03954352,0.02817555,0.049613427,-0.017033998,0.024581183,-0.015462009,0.016638655,-0.0057832035,-0.07676864,0.03213285,-0.04828273,0.051160097,-0.01229137,0.058388535,0.009624579,-0.027823512,0.0069009443,0.022117937,0.01807151,-0.034942858,0.0034523301,-0.07654695,-0.04848322,0.055685688,0.011496916,-0.0072947536,0.034056384,0.016679835,-0.020408379,0.07551906,-0.08103393,-0.023252016,-0.013044739,-0.0511694,0.020805292,0.02132456,-0.041335218,0.027893314,-0.022869952,-0.026449122,0.008001451,0.020932008,-0.016454427,-0.03517615,-0.004413912,-0.017807258,0.018310508,0.017531117,-0.0046374965,0.01953064,0.03899339,-0.05376641,-0.032377295,0.0073143276,0.0020861032,0.07775373,0.03954295,-0.028914528,0.0017177691,0.05003702,-0.032460723,0.024512876,-0.06383444,-0.006875939,0.038958956,0.055378586,0.04360636,0.03115611,0.047112238,-0.050067388,-0.010932268,0.021866538,-0.06556927,0.045200475,-0.011669436,0.05811716,0.018760378,-0.029312057,0.032520194,0.051722884,-0.027261812,-0.007555472,0.020173587,0.030953137,-0.051933814,0.04347094,0.013555047,-0.011325773,0.044304095,0.024479702,0.017350435,-0.03226434,0.017726915,0.026097827,-0.020477576,0.045254655,-0.06366977,0.025853802,-0.011175817,-0.00743282,-0.02175716,-0.005001981,0.04209918,0.006964962,0.012779638,-0.05527536,0.019277303,0.02172324,0.023002977,0.033008426,-0.09025366,-0.020111527,-0.011123206,-0.0027379326,-0.018074293,-0.0052957046,-0.013238356,0.028977793,0.011020447,0.010369952,-0.05206969,0.015557185,0.029522846,-0.011103557,0.005099487,0.013154816,-0.032899477,0.035479292,-0.029585157,-0.017330717,-0.0036980372,-0.039131265,0.009044681,-0.033408053,0.0071339966,-0.0129485885,-0.022186747,0.019864572,-0.0023032736,0.06129222,-0.053346083,0.04249454,-0.03760542,0.03667312,-0.117156394,0.04157379,0.05213254,0.0060602813,-0.011180078,-0.043862928,-0.08815842,0.008755666,-0.054551117,0.022121945,-0.01808693,-0.051130395,0.0061972835,0.020891728,0.03408897,0.0138556175,0.041300457,-0.013219142,0.019968934,0.018556824,-0.0065870536,0.033170607,0.0077128415,-0.050793275,0.0018294689,0.020860761,0.0438562,-0.1137497,0.039617315,0.048771318,-0.044421267,-0.04141065,0.049393896,0.043074604,-0.00035369457,-0.023103435,0.043127924,0.016043622,-0.051766083,0.0038449697,0.034860283,-0.0022747915,-0.027143974,-0.026087383,-0.011398407,-0.0146202445,0.027224753,-0.024825843,0.03464208,0.041779887,-0.036936123,0.1289823,-0.0028322395,-0.017706973,-0.029524965,0.03107865,-0.008852162,0.0062447917,0.016580176,0.043876518,-0.017307052,0.00974107,0.012303109,-0.025304008,-0.011864516,0.0319088,-0.043631714,-0.0011137807,-0.024589922,0.045297295,-0.021098176,0.018998915,-0.026455661,0.020834815,-0.11736153,-0.053340413,0.036806803,-0.010515479,-0.009893661,0.045579795,-0.037381377,0.008464118,-0.014428888,0.023552855,-0.02633604,0.018026644,-0.024578404,0.00390934,-0.04314993,-0.0066107395,-0.014726008,0.05680852,0.015541795,-0.031969473,0.052115772,-0.0075450125,0.04735575,0.0077154622,0.03786512,0.008662786,-0.03943171,0.018193657,-0.03836399,0.0023332937,0.007029554,0.003035319,-0.0060545406,0.011665881,-0.021996858,-0.006990924,0.078044295,-0.062212564,0.0068034027,0.036798242,-0.032956988,0.035303906,0.026546797,-0.029215215,-0.010422285,0.00817407,-0.05831258,-0.04685205,-0.0066734767,0.010019843,0.02111662,0.041188005,-0.003627246,0.016520359,0.012451759,-0.21592982,0.016468482,-0.026780777,-0.03895349,0.008929985,0.039145056,0.022534177,-0.016029915,-0.018103266,0.019450365,0.030378075,-0.022527903,0.03163169,-0.027329301,-0.060617656,0.018952848,-0.005730908,-0.006638448,0.029365592,0.0066666515,0.013285783,0.06137075,-0.05667625,-0.016189674,-0.018321138,-0.01635389,-0.038995985,0.013419514,0.018701153,-0.0063193524,0.033987157,-0.015716868,0.04109322,0.02817453,-0.022684248,-0.035777178,-0.012160089,-0.0022474418,-0.08906805,0.043140717,0.015038788,-0.0020410295,-0.052931406,0.0024160575,0.029806942,0.04834512,0.01291434,0.034152463,-0.025555689,0.020809717,0.003469534,0.016080957,-0.11488909,0.008680903,-0.0030824624,0.06355536,0.021369956,0.0010339766,0.010313323,-0.026090207,0.05096068,0.08156875,-0.020057412,0.008961353,-0.0189076,-0.008143426,0.054057915,-0.032223336,-0.020505887,0.014334615,0.06540235,-0.04788308,-0.0045458726,-0.009403422,0.028278856,-0.020301655,0.014453173,0.0028221754,-0.076639324,0.020419434,-0.036993995,-0.02720163,-0.01250221,0.038268633,-0.038025185,-0.017373731,-0.034756187,0.03160874,0.040076464,0.013279412,-0.017587416,-0.034748163,-0.042313367,0.03560161,0.02076528,-0.027499184,-0.043132093,0.036584567,-0.015452702,-0.019261066,0.027324818,0.013325339,-0.023915328,0.033933707,0.04893294,-0.04681682,-0.13127859,0.029092602,-0.025198609,-0.032234117,0.035071127,0.031443603,0.04624232,-0.027126368,0.0017000604,0.03057153,0.009643196,-0.027128773,-0.046323642,-0.041479416,-0.014895631,-0.02441359,-0.001712475,0.004925744,0.031044839,0.018190863,-0.020314412,0.04971188,0.0064956048,0.04353499,0.012234631,-0.08326685,0.031634472,-0.01188198,-0.038729895,0.03200263,0.0150893,-0.0075581814,0.03939666,0.010621539,0.05502434,-0.06281743,-0.03400963,0.044811156,0.0043381434,0.033211753,0.003875502,-0.012536433,0.00082478323,-0.0051614232,-0.011338001,-0.0910466,0.011689923,-0.016646586,0.0047106585,0.018144796,0.019517083,0.0345048,0.0077921697,0.03857912,-0.014013248,-0.049811777,-0.0018488738,-0.003701019,-0.0015132519,0.003317836,-0.016051522,-0.038598098,0.0051956167,0.050060846,-0.03563672,0.032495342,0.028224008,0.018454408,0.024788728,-0.028360471,0.03778584,0.004331457,-0.029292108,0.021244088]
7	project_members	Table: project_members\nDescription: junction table เชื่อม user กับ project พร้อม role user ต้องเป็นสมาชิก team ก่อนจึงจะเข้าร่วม project ได้\nColumns:\n  id         UUID PRIMARY KEY,                                        -- รหัส\n  team_id    UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,     -- FK → teams\n  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,  -- FK → projects: project ที่ user เข้าร่วม\n  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,     -- FK → users: user ที่เป็นสมาชิก project\n  role       TEXT NOT NULL,                                            -- MANAGER (ควบคุม project) / CONTRIBUTOR (บันทึก time entry ได้) / VIEWER (ดูอย่างเดียว)\n  created_at TIMESTAMPTZ NOT NULL,                                     -- วันที่เพิ่มเข้า project\n  updated_at TIMESTAMPTZ NOT NULL                                      -- วันที่แก้ไขล่าสุด\n  -- UNIQUE (project_id, user_id): user อยู่ใน project เดียวกันได้แค่ครั้งเดียว\n	[0.013882419,0.026056632,-0.030468268,0.024143785,0.017525215,-0.014702072,-0.01906105,-0.052219756,0.034824803,0.006329349,0.01993924,0.020306641,0.10931524,0.03386699,-0.030082883,-0.012001504,-0.009781017,-0.00848356,0.025161445,-0.0166457,0.037683018,-0.045482438,0.03999179,-0.013387644,0.024194833,-0.028360816,0.0073162136,-0.008554129,-0.049818486,0.009979887,0.031898998,-0.025274195,-0.0020598082,0.037416957,0.020664841,0.014996221,0.010779769,-0.021420017,0.0066106347,-0.012028799,0.021920765,0.00014693564,0.02746046,-0.030089447,0.008476502,-0.0066211657,0.041015748,0.042054337,-0.0066365404,-0.019364925,0.028056972,0.005672777,0.04319845,0.009438381,-0.03204425,-0.018030569,0.034520183,0.04809888,-0.037937522,0.0071680914,0.012930102,0.038843714,-0.011998539,0.011407978,0.020221304,-0.0020535018,0.011609211,-0.028646046,-0.048245765,-0.023960836,-0.01737959,0.01730778,0.09875374,-0.018466987,-0.008200266,0.00021163645,-0.04330684,0.02397143,0.030262072,-0.015837155,0.071406975,0.029111087,0.024695361,0.0034192884,-0.009920206,-0.011941703,-0.016517628,0.04830387,0.032767646,0.048865788,0.029255953,-0.0427395,-0.03899853,0.028186401,0.029470012,0.01802941,-0.003876601,0.010825675,0.04537194,-0.041564863,0.00056838675,-0.08315399,-0.030756125,-0.032581568,-0.08453384,-0.04000905,-0.0071673323,-0.035850346,0.041946083,-0.017387342,-0.0044554435,0.0101932585,0.022714507,-0.053513397,0.04485184,-0.06150497,0.0597242,-0.058052875,0.01885611,-0.057932537,-0.050553143,0.0031786128,-0.010588085,-0.012559701,0.04583314,-0.02485226,0.009859852,0.0009957203,0.016213335,-0.043202154,-0.017998584,-0.05118941,0.027062979,0.012467849,-0.031632278,0.05921063,0.023575202,0.0011138885,0.0029117444,0.009881467,0.03808833,-0.019507876,0.0103428075,0.031561065,0.0067115407,-0.07645994,-0.011107706,0.02062251,-0.033576425,0.0073672454,0.047532983,-0.059844464,-0.04055447,-0.015776968,0.03600182,-0.008860781,-0.034012724,-0.020357464,-0.0048485226,0.04026217,0.030744057,-0.0034879944,0.022822859,-0.038422607,0.035662636,0.025922826,-0.023365958,0.027408976,-0.034220375,0.009612746,0.012932303,-0.062363144,-0.07510738,0.039006446,-0.034618232,-0.022903297,-0.0295546,-0.046644516,-0.036452208,-0.05770849,-0.07086106,0.0062641557,-0.05781748,0.026055,-0.023674814,-0.009765389,-0.025332874,-0.03570594,0.046443675,0.022358852,-0.018448519,0.055315025,0.020303067,0.037370905,0.035459973,0.012119526,0.016400715,0.018324653,0.013477407,-0.033012453,0.0141537,0.009924712,0.03804048,0.023075506,0.022257876,-0.07116777,-0.010317234,0.03592449,0.014402757,0.016124597,-0.018818172,0.01622698,-0.023869349,0.054170605,-0.019815959,-0.038196284,0.033279683,0.014383059,-0.030128404,0.04573201,-0.0027803732,-0.02409556,0.06382953,0.03359869,-0.011553712,0.02544975,0.022682901,0.0059739286,0.04062396,0.027105471,0.06885501,0.0975455,-0.049581975,0.022803951,-0.021360544,9.47986e-05,0.016537953,-0.012244253,-0.017813295,-0.10439035,-0.037301984,0.021469735,0.017585896,-0.018242093,0.03003237,-0.021589447,-0.03459907,0.02523498,-0.06116477,0.013152752,0.032609228,-0.04631736,-0.0022399002,-0.04679008,0.017714884,0.0113902055,-0.023196222,0.0243488,0.039937332,0.0048284996,0.024373338,-0.0012526993,0.013486519,-0.038325164,0.029951334,-0.004376337,0.018648885,-0.0218571,-0.067198426,0.009652216,0.009284222,-0.0134947095,-0.041754507,-0.004718291,0.016640475,-0.0100743435,-0.056337517,0.012848979,-0.019931147,-0.045163162,-0.028012589,0.043886174,-0.07318649,-0.035821274,-0.018646158,-0.012325778,-0.039410785,-0.0026066506,-0.0401222,0.009633682,0.0108108595,0.08681467,-0.02529265,0.012934816,0.055486307,0.013886422,0.038037702,0.023236267,-0.013712459,-0.014106941,-0.0133591695,-0.022500549,0.047897223,-0.05999813,-0.014526731,0.033374492,0.12489538,0.014628463,-0.03803578,0.040613934,-0.026911302,-0.024363032,-0.027952956,0.028344799,0.021655703,-0.03539716,0.0026855627,0.06162469,-0.0108597595,0.047373783,-0.0290501,0.03894477,-0.016726553,-0.071117654,0.027498052,-0.053609136,0.034285717,-0.007832899,0.06801303,0.034911554,-0.01418151,-0.009347597,0.014513125,0.034671783,-0.029229263,0.034635354,-0.056370623,-0.06416185,0.06366943,0.0010990321,-0.022319801,0.023776583,0.023272205,-0.02346714,0.06258285,-0.07008656,-0.028455285,-0.07200148,-0.027612384,0.0092462255,0.029007861,-0.05634652,0.011349794,-0.024395194,-0.027118634,0.012823808,0.006903693,0.00044538977,-0.013401714,-0.011393118,-0.01704588,0.026114805,0.015012329,0.0031766952,0.007148559,0.021569334,-0.071155146,-0.02100733,-0.0046692905,0.007995503,0.116413124,0.040854096,-0.04912497,-0.0066578537,0.04214241,-0.041089535,0.026560774,-0.07317287,-0.010635521,0.0364792,0.049440373,0.0402236,0.028631259,0.040388145,-0.039082773,-0.013463164,0.03347598,-0.050974395,0.016312046,-0.004150781,0.04223838,0.006077142,-0.009742876,0.05606947,0.043198023,-0.026174186,0.027431678,0.005398905,0.013859593,-0.036503386,0.040854562,0.027174361,0.0041918224,0.053597543,0.036510173,0.006990559,-0.0011260797,0.04518958,0.037165985,-0.030082732,0.04947408,-0.06454341,0.05471823,0.027012862,0.007073259,-0.024234459,0.0075739347,0.037564043,-0.0154121155,0.016560744,-0.05352149,0.007207922,0.032295126,0.020126443,0.028454894,-0.08910368,-0.0029230197,-0.015216223,-0.013443335,-0.0013869406,-0.025756946,0.008737575,0.010577918,0.014141279,0.032150216,-0.04740684,0.013259101,0.018900197,-0.022553314,-0.005486508,-0.00636499,-0.045256086,0.0071095903,-0.011374663,-0.024027588,-0.022162007,-0.021433968,0.015040293,-0.052997995,-0.015376371,-0.007974892,-0.0047575664,0.013205157,-0.0055057565,0.03279297,-0.060464222,0.033276595,-0.03419357,0.022925708,-0.12330533,0.035055,0.033265963,-0.023915188,-0.017518997,-0.04478682,-0.078938596,0.021333832,-0.061592344,0.044315297,0.0015542018,-0.033696454,-0.009665674,0.0025397239,0.044194125,0.016245496,0.04153958,-0.023805045,0.028033642,0.020096404,0.0013940202,0.030866839,-0.017834738,-0.023377264,-0.004285634,0.0071630627,0.04734386,-0.08441554,0.031176949,0.04356523,-0.045187477,-0.04230122,0.026433574,0.06041661,-0.0020106044,-0.029093863,0.022680344,0.0074931365,-0.051619764,0.06152876,0.031959437,-0.008080007,-0.03816342,-0.04291856,-0.013908294,-0.027618032,0.01212969,-0.04103124,0.036989577,0.046871584,-0.050819594,0.118614644,-0.0027643042,-0.01874533,-0.018806867,0.0126187205,-0.0017858709,0.0035810198,0.027801018,0.0075199795,-0.015480751,-0.025487263,0.011403935,-0.0499739,-0.029543344,0.019252552,-0.05657467,0.009707454,-0.027989227,0.049840268,-0.036675304,0.02118762,-0.06275636,0.01926126,-0.09747711,-0.06598269,0.036838293,-0.0074886894,-0.030282883,0.023288049,-0.041007686,0.008852431,-0.019436182,0.04745508,-0.02918483,0.022906115,-0.040175162,0.016845,-0.016860463,-0.016686914,0.016826496,0.059289917,-0.012491453,-0.022401702,0.058405917,-0.03806887,0.04017318,0.020034099,0.01201,0.0015684679,-0.037032817,0.010652578,-0.021748805,0.013747061,0.004204102,0.0018069167,-0.0056038243,0.031565353,-0.026417373,-0.0103722755,0.062166214,-0.07703526,0.03654731,0.046542883,-0.025629131,0.039143387,0.024943054,0.0024452957,-0.0049044644,0.00605417,-0.059924755,-0.06180226,-0.017293954,-0.009758994,0.037993964,0.036435492,0.0027358185,0.033764362,0.024050951,-0.21001536,0.0014213079,0.004945934,-0.033961568,0.00018642306,0.025959905,0.00614657,-0.019147094,-0.00724857,0.0024690712,0.04608748,-0.036251217,0.0028243696,-0.023352098,-0.056349292,0.020368464,-0.01125601,-0.03480877,0.028148292,0.057706468,-5.1380506e-05,0.06398311,-0.038757794,-0.01199894,-0.027085546,-0.0032441677,-0.0068183825,0.031750765,0.027938664,-0.0052831476,0.03801412,-0.0013860773,0.039718095,0.024845725,-0.01890956,-0.035861477,-0.013832643,0.010956013,-0.07577413,0.041865274,0.011623609,-0.012284644,-0.060398433,0.012974049,0.01963584,0.05747682,0.036048554,0.04522414,-0.030773612,0.00026445373,0.006143508,0.0048348056,-0.08498641,0.020413348,0.005976304,0.08818526,0.02244696,0.016873881,0.053683784,-0.023401298,0.043469768,0.06388693,-0.02409101,-0.00831821,-0.011196734,0.022857923,0.055490203,-0.045478567,-0.011028198,-0.00867966,0.050145682,-0.03602847,-0.019344259,0.00311441,0.024034198,-0.032917246,0.00321316,-0.0063114865,-0.09231175,0.0021487086,-0.034199454,-0.023451364,0.0058845556,0.03435591,-0.02684126,-0.027596954,-0.051666427,0.026891466,0.04900403,0.0294965,-0.023205886,-0.04804591,-0.034567166,0.007245264,0.0013849798,-0.02990099,-0.037729923,0.035406623,-0.010352847,-0.026238268,0.01492877,0.026580209,-0.041012622,0.021998452,0.04376394,-0.051424075,-0.11375661,0.008084398,-0.018284976,-0.035588533,0.052346684,0.011310905,0.034007777,-0.014979818,0.0017523479,0.009756642,0.022954684,-0.027846022,-0.022109848,-0.025962919,-0.013171938,-0.02382158,-0.0032402626,-0.010635489,0.020317439,0.012036993,-0.03982302,0.044655167,0.011990268,0.037464354,-0.0015953261,-0.07847319,0.053345013,-0.022910602,-0.025686951,0.030273123,0.032487154,-0.0084737195,0.04913978,-0.0003453844,0.0702037,-0.05426597,-0.04593117,0.032895993,-0.0009754405,0.018797822,-0.014981786,-0.012037905,0.033700265,-0.017720873,-0.009506473,-0.092885785,0.02461788,-0.016555006,-0.0061855665,0.028772905,0.03745449,0.046385042,0.00706763,0.027776577,-0.01983165,-0.040533815,-0.018031485,0.022238908,0.0050509935,0.006293764,-0.017697588,-0.033790447,0.025113901,0.0334055,-0.03430757,0.063995175,0.030850755,0.011969691,0.027602207,-0.024421226,0.04088641,-0.00063508516,-0.03108374,0.031562936]
8	project_tasks	Table: project_tasks\nDescription: งานย่อย (task) ภายใน project แต่ละ task มี status, billable flag และกำหนด hourly rate ของตัวเองได้ (override rate ของ project)\nColumns:\n  id                UUID PRIMARY KEY,                                        -- รหัส task\n  team_id           UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,     -- FK → teams\n  project_id        UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,  -- FK → projects: project ที่ task สังกัด\n  name              TEXT NOT NULL,                                            -- ชื่อ task ความยาว 1-255 ตัวอักษร unique ภายใน project (case-insensitive)\n  description       TEXT,                                                     -- รายละเอียดของ task\n  status            TEXT NOT NULL DEFAULT 'active',                           -- สถานะ: active / completed / on_hold / archived\n  billable          BOOLEAN NOT NULL DEFAULT TRUE,                            -- true = เวลาที่บันทึกในงานนี้คิดเงินลูกค้า / false = งาน internal ไม่คิดเงิน\n  hourly_rate_cents INTEGER,                                                  -- ราคาต่อชั่วโมงเฉพาะ task นี้ หน่วยสตางค์ ถ้ามีค่าจะ override ราคาของ project และ client\n  tags              TEXT[] NOT NULL DEFAULT '{}',                             -- array ของ tag\n  order_index       INTEGER                                                   -- ลำดับแสดงผลใน UI\n	[0.012406489,0.032629237,-0.009437901,0.012898556,0.022065515,-0.026377201,-0.031732216,-0.024370102,0.038831487,0.041734267,0.03586434,0.022319326,0.11328686,0.05030186,-0.017565183,-0.034946017,0.007136852,-0.02419566,0.014169871,-0.021429026,0.029771965,-0.040423103,0.030998545,-0.002311877,0.035878856,-0.014138098,0.017295301,-0.012891404,-0.04283218,0.03096486,0.034084063,-0.008137583,-0.006777237,0.014720213,0.0114471,0.0028295186,-0.0006656774,-0.034347944,-0.0032282893,-0.0064614504,0.03660931,-0.01968762,0.04536513,-0.028821982,0.017545031,-0.0198993,0.05478185,0.018422948,-0.012824865,-0.022306882,0.022113688,0.013731552,0.028427545,0.027531475,-0.037485413,-0.010375848,0.04954122,0.028518587,-0.033985455,-0.0010547723,0.0042246636,0.04677982,0.0032527626,0.023673473,0.02015042,-0.01410777,0.028981963,-0.034563877,-0.057773322,-0.021473043,-0.022740876,0.02712227,0.095696606,-0.0171196,-0.027182138,-0.004407629,-0.03140198,0.011187687,0.022331098,0.004136726,0.057126235,0.02175898,0.014166231,0.050593186,0.018002618,-0.0002635507,-0.03146621,0.050199714,0.04502849,0.026406517,0.02051376,-0.028624447,-0.053473204,0.02330787,0.024302302,0.024868475,-0.005753266,0.008089033,0.03619717,-0.024112107,-0.009481996,-0.0690603,-0.0042551933,-0.03323292,-0.08591956,-0.028468974,-0.008006275,-0.04697044,0.038165547,-0.009901851,-0.021599768,-0.005743389,0.016778506,-0.04325367,0.038123965,-0.07359376,0.06837826,-0.058454882,-0.0068037775,-0.07020566,-0.042323038,0.015701523,-0.009609962,-0.023192024,0.039062407,-0.02056372,-0.012695612,-0.020515924,0.015850307,-0.06781591,-0.009292435,-0.017882654,-0.003627286,0.008957087,-0.013156668,0.06177284,0.028563062,0.010326451,-0.006380672,0.022427067,0.015761903,-0.035509653,0.008553579,0.05083379,0.013717825,-0.06745736,-0.022128887,0.022975814,-0.013460736,0.022849482,0.04283269,-0.060559943,-0.040369615,-0.0032833677,0.06132631,-0.0067762616,-0.04799056,-0.0014315316,0.015036089,0.02787616,0.029391343,-0.00378381,0.024429275,-0.035743557,0.042298596,0.008714394,-0.033774793,0.018540595,-0.049328625,-0.011270517,0.018822502,-0.043649055,-0.07524932,0.03877625,-0.027894365,-0.02268297,-0.022938607,-0.025389275,-0.01730295,-0.036209997,-0.06975788,0.010836141,-0.043080218,0.024063678,-0.014602428,-0.0143132275,-0.021679576,-0.021292375,0.049919184,0.02061525,0.00021874813,0.09604544,0.017775794,0.02908404,0.02450387,-0.0025988377,0.03712757,0.0059688566,0.0086958455,-0.025821168,0.0040242025,-0.0052486868,0.019100567,0.045282878,0.008688694,-0.052463338,-0.009178159,0.02511704,0.008331343,0.012057229,-0.01744307,0.021406166,-0.038137447,0.047057275,-0.026753057,-0.06196128,0.0356975,0.019276531,-0.022989366,0.051005363,0.005855862,-0.065829575,0.07516817,0.03590892,-0.022730438,0.0071831485,0.020687653,-0.004945695,0.022595389,0.022927439,0.045044255,0.09733749,-0.046773717,0.017420638,-0.030135099,-0.01725662,0.064376935,-0.021219237,-0.023727307,-0.10282515,-0.055778384,0.021662682,0.016134677,-0.023528533,0.032159463,-0.020251665,-0.040260218,0.030635413,-0.058145273,0.02998226,0.033785544,-0.050337836,0.007752228,-0.015216236,0.025721096,-0.0019864936,-0.044982683,0.008154847,0.061058022,-0.00013146938,-0.0029520374,0.0010765808,0.015008662,-0.031625994,0.032718655,0.002656336,-0.0052756593,-0.034873195,-0.06536131,0.008676753,-0.002063444,-0.024563104,-0.04188053,0.011281806,0.0037655183,5.633884e-05,-0.059467148,0.024107315,-0.008730385,-0.05554696,-0.018270837,0.03862964,-0.07513708,-0.025170866,-0.031069294,0.0033286184,-0.05138394,0.004948202,-0.02512691,-0.00609918,0.013295283,0.08159548,-0.0058518066,0.0028470792,0.07310052,0.007974414,0.007892588,0.012859023,-0.018904658,-0.0067611835,-0.02466729,-0.021639988,0.04193717,-0.043166485,-0.03850008,0.023380788,0.12260027,0.026413253,-0.06191889,0.03306328,-0.0077653625,-0.013432816,-0.00973741,0.042172655,0.032093737,-0.05693977,0.016077593,0.058079336,-0.010095643,0.03453155,-0.023109922,0.038164314,-0.013653926,-0.09341146,0.043599524,-0.046617374,0.03275005,0.0015872975,0.050948296,0.029675314,-0.010361884,-0.0063430076,0.02132946,0.019591706,-0.034760714,0.041030303,-0.06358192,-0.055515084,0.060337957,-0.007343221,-0.017927859,0.04638441,0.03227178,0.011772936,0.06361132,-0.077216126,-0.022184703,-0.054473117,-0.05516927,0.014662591,0.013839959,-0.04595335,0.004639022,-0.032296672,-0.03548972,0.01480718,0.012153008,-0.018224522,-0.00043822455,-0.014324726,-0.0027066665,0.019471109,0.014982928,-0.015042145,0.020876562,0.030055474,-0.052844953,-0.034740932,0.0066328417,0.0048786285,0.08672397,0.055849478,-0.033357985,0.0004928463,0.047912017,-0.028623238,0.016241139,-0.07213347,-0.010015838,0.041421704,0.038446937,0.03148426,0.032733075,0.033654645,-0.0409283,-0.006854353,0.018627824,-0.05603311,0.0407703,0.003287195,0.035283066,0.0057725264,-0.014817012,0.055683065,0.03504821,-0.054000426,0.0045751208,0.014663624,0.008893531,-0.042725697,0.054045927,0.022581054,-0.013855938,0.05102315,0.044089507,0.014086705,-0.013394182,0.047616113,0.034663167,-0.02222176,0.021919215,-0.05429472,0.04882115,0.013427126,0.02142662,-0.027844666,0.017575404,0.05039969,7.0837166e-05,0.014373221,-0.06803417,0.0043476764,0.021546077,-0.0008457492,0.036204666,-0.075488456,0.011897315,-0.010472367,-0.019717136,0.0063139065,-0.010929755,0.020521874,0.015833005,0.016085288,0.031676464,-0.043365657,0.024929175,0.01655008,-0.011252848,-0.0016543806,-0.023108,-0.03428465,0.018130632,-0.009797299,-0.019256182,0.009326899,-0.03499139,0.013173189,-0.037487157,-0.015983528,-0.016681425,-0.011621532,0.011441135,-0.019387865,0.024832234,-0.052489944,0.065708764,-0.0007788869,0.0138924895,-0.122009605,0.004034718,0.031735916,0.014674921,-0.016486997,-0.04693156,-0.06397836,0.022700228,-0.075456016,0.038128342,0.0057393853,-0.026854558,-0.009791843,-0.023870118,0.035582226,0.009270954,0.042545266,-0.004121685,0.034246527,0.022784773,-0.017216798,0.039965212,-0.03225501,-0.046593115,-0.002622171,0.006025403,0.05723481,-0.106904015,0.024318494,0.04055321,-0.0467033,-0.020580716,0.044530857,0.032627963,-0.0074454793,0.0013765122,0.038999017,0.019664144,-0.06688706,0.06319124,0.038133845,-0.02303914,-0.046046942,-0.045001246,0.008223518,-0.03713747,-0.008001096,-0.022667503,0.021288767,0.034241892,-0.040919874,0.12816912,-0.009749019,-0.030799745,-0.015772378,0.01659493,0.010482146,-0.01941676,0.028830046,0.014515417,-0.032483432,-0.02341458,0.030252911,-0.017333109,-0.020957489,0.014857517,-0.0468833,0.016971255,-0.03548796,0.051591065,-0.005014963,0.022650726,-0.030791067,0.018856386,-0.12292996,-0.08024902,0.041030403,-0.023199612,-0.013510746,0.0248948,-0.031699628,0.004201556,-0.01498872,0.017218048,-0.03143126,0.016384639,-0.055893634,0.026721809,-0.0061693355,-0.013790356,-0.012107379,0.05593549,-0.02263631,-0.02915371,0.060488928,-0.013478293,0.06603318,0.016373828,0.015163498,-0.0070737903,-0.024405107,0.007652155,-0.0332625,0.010075657,0.014138542,0.008624871,-0.016502377,0.036208577,-0.026887484,-0.015912814,0.061146356,-0.0600858,0.025900997,0.042556033,0.0023653517,0.022344671,0.015358983,-0.007958009,-0.010886226,-0.014655032,-0.05065016,-0.060901802,0.009361296,0.013702528,0.021364816,0.0506398,-0.005369712,0.01973442,0.018472021,-0.20218316,0.016950948,-0.005365922,-0.04191287,-0.010453842,0.037068993,0.0174622,-0.028342986,0.0026404036,0.0381399,0.034991622,-0.040312782,0.02680941,-0.02505611,-0.039047647,0.0033603834,-0.0021487689,-0.012293687,0.009999081,0.015525481,0.0036588209,0.06812007,-0.036803305,-0.016757367,-0.03304785,-0.034299016,0.013272169,0.019226605,0.021424873,0.0025069478,0.036643665,-0.0151464725,0.048313513,0.010711081,-0.027172452,-0.0196932,-0.0032561286,-0.0039324854,-0.10374781,0.03200647,0.02903732,-0.0055593806,-0.051602952,0.016102921,0.0014322953,0.05863453,0.018815622,0.04318081,-0.02610506,-0.004531892,0.025656618,0.0063460623,-0.09264762,0.0039770366,-0.007964373,0.058583368,0.02064117,0.004708731,0.02710135,-0.029737487,0.05186709,0.054697108,-0.012068815,-0.0005246748,-0.011279769,0.0062570125,0.054999765,-0.023014197,-0.005321261,0.0062923124,0.054334514,-0.03749174,-0.014537767,-0.013601996,0.04023911,-0.022585243,0.015451934,-0.007855818,-0.059676416,0.010405741,-0.044198483,-0.047459263,-0.019317804,0.038706046,-0.041655365,-0.030964848,-0.06445782,0.016844284,0.02843539,0.020124437,-0.0082177175,-0.04796308,-0.02004167,0.0021362419,0.02529315,-0.019842107,-0.04480236,0.017216926,-0.025886644,-0.000837578,0.030093983,0.01183271,-0.031545963,0.038415585,0.047617137,-0.04735351,-0.11332508,0.028619299,-0.032681946,-0.04002582,0.046815664,0.03251539,0.048866067,-0.026374498,0.0066019627,0.006994335,0.019030048,-0.050528165,-0.026149904,-0.04711053,-0.018348858,-0.03516264,0.0022315264,0.009884551,0.028564263,0.022244833,-0.03519888,0.06034286,0.011998496,0.030141236,-0.0034390085,-0.06960399,0.032563534,-0.016242584,-0.027098434,0.029192796,0.003065133,-0.0031841034,0.019530741,0.019358251,0.0725345,-0.05195224,-0.015382271,0.061904363,-0.0052620443,0.011004984,-0.017045947,-0.015366904,0.007310176,-0.029938655,-0.026788767,-0.10275468,0.010831452,-0.013766174,-0.02596982,0.029562557,0.014034708,0.033989944,0.011959499,0.039586097,-0.034631312,-0.054435827,-0.003949654,-0.012732325,-0.007933575,-0.007385132,-0.000888037,-0.04251362,0.023462288,0.033743076,-0.030576041,0.06309078,0.0312355,0.021362185,0.02210403,-0.0065448224,0.049054943,-0.0035160284,0.0010913098,0.034455735]
9	projects	Table: projects\nDescription: งานหรือโครงการที่รับจาก client มี status, budget, timeline และ tag มี rate ค่าบริการเป็นของตัวเอง (override จาก client)\nColumns:\n  id                        UUID PRIMARY KEY,                                      -- รหัส project\n  team_id                   UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,   -- FK → teams: team เจ้าของ\n  client_id                 UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE, -- FK → clients: client เจ้าของ project\n  name                      VARCHAR(255) NOT NULL,                                  -- ชื่อ project unique ภายใน team (case-insensitive)\n  code                      TEXT,                                                   -- รหัสย่อ project เช่น GL-001, FF-002\n  description               TEXT,                                                   -- รายละเอียด project\n  status                    TEXT NOT NULL DEFAULT 'active',                         -- สถานะ: active / completed / on_hold / archived\n  color                     TEXT,                                                   -- สี hex สำหรับแสดงใน UI เช่น "#4CAF50"\n  tags                      TEXT[] NOT NULL DEFAULT '{}',                           -- array ของ tag เช่น {web, nextjs, ecommerce}\n  default_hourly_rate_cents INTEGER,                                                -- ราคาต่อชั่วโมง default หน่วยสตางค์ override ค่าจาก client\n  budget_type               TEXT,                                                   -- ประเภท budget: none / hours / amount\n  budget_hours              INTEGER,                                                -- จำนวนชั่วโมงสูงสุด ใช้เมื่อ budget_type = 'hours'\n  budget_amount_cents       INTEGER,                                                -- วงเงิน budget สูงสุด หน่วยสตางค์ ใช้เมื่อ budget_type = 'amount'\n  start_date                DATE,                                                   -- วันเริ่มต้น project\n  due_date                  DATE,                                                   -- วันกำหนดส่ง project\n  archived_at               TIMESTAMPTZ                                             -- ถ้ามีค่า = project ถูก archive แล้ว\n  -- Rate resolution order (ลำดับความสำคัญของราคา): task > project > client\n	[0.013572731,0.03509857,-0.01479509,0.01905884,-0.008873019,-0.013630053,-0.023975536,-0.032723688,0.025632218,0.05263302,0.029801298,0.0249624,0.11736353,0.041374337,-0.026656255,-0.045515627,-0.0022105249,-0.016400926,0.016665855,-0.0166769,0.051322255,-0.035788145,0.04135607,-0.018258916,0.031070298,-0.011638209,0.009081892,0.00059557514,-0.06231893,0.03200807,0.035368945,-0.014679718,0.007961627,0.047330435,0.014457317,0.021648921,0.002508651,-0.03476422,-0.0063327663,-0.0066543715,0.034118064,-0.0003744032,0.053567402,-0.048803296,0.027508454,-0.022791732,0.055988923,0.012666411,-0.006819176,-0.019261237,0.030414574,0.010852815,0.04646414,0.0151641965,-0.04652744,0.002877874,0.048337065,0.035667,-0.028317034,-0.014548804,0.0065446347,0.043264262,-0.007825714,0.027702654,0.019333554,-0.00518121,0.018083017,-0.03896409,-0.065615185,-0.028230352,-0.018618308,0.011817112,0.10257231,-0.014321094,-0.004466123,-0.0047569424,-0.034694906,0.0031163502,0.01607282,-0.010314984,0.0678525,0.03292433,0.0038011894,0.04651524,0.022321386,-0.0046670535,-0.04842225,0.04134752,0.042102944,0.019413065,0.018737912,-0.030652653,-0.027348094,0.020753417,0.020901538,0.021172887,0.0033425095,-0.0044666654,0.037922397,-0.025223467,-0.010509966,-0.07429035,0.0014990593,-0.025783189,-0.10050997,-0.030984243,-0.024037685,-0.039397594,0.046639826,-0.029045865,-0.034204382,0.0035464126,0.029541356,-0.029525463,0.03125522,-0.067950614,0.061345518,-0.049294576,-0.011478529,-0.05512813,-0.03364856,0.006108327,-0.0057954644,-0.025837062,0.02980968,-0.02200301,-0.0053362455,-0.01039429,0.02295843,-0.07579959,-0.016278075,-0.029280188,-0.0059831887,0.011440514,-0.006591384,0.0684904,0.028861076,0.014733489,-0.010287934,0.013130623,0.023405993,-0.033976976,0.005831888,0.063648,0.021702165,-0.052874614,-0.016591687,0.016606404,-0.017110227,0.013028284,0.0466214,-0.064013585,-0.035851303,-0.0018503454,0.051868785,0.0032596965,-0.052186027,-0.011873768,0.021694267,0.021505775,0.031816285,0.0064250967,0.008935828,-0.02780626,0.046931263,0.011306917,-0.020792095,0.014762887,-0.043665223,-0.017499268,0.011080944,-0.044675753,-0.066184245,0.0363477,-0.0065314393,-0.026649352,-0.02338404,-0.03163099,-0.023090575,-0.048884634,-0.05804568,0.005300663,-0.05318951,0.025013147,-0.022716453,-0.019095315,-0.03397845,-0.01616672,0.04026164,0.013171877,0.0071267127,0.08915894,0.026913483,0.031628832,0.03430653,-0.0057430654,0.03162323,0.015009547,-0.007886142,-0.045779552,0.021543665,-0.010307752,0.028410895,0.044349987,0.005839002,-0.05183056,0.012041496,0.03703522,0.0031151094,0.02240944,-0.003794311,0.024892913,-0.045871094,0.046307337,-0.025823692,-0.07486279,0.028093709,0.02111682,-0.030640326,0.053343028,0.0051733376,-0.07845666,0.07125159,0.036517657,-0.01420498,0.0029745658,-0.0022455866,-0.0079092,0.029518813,0.011177465,0.040269215,0.09210904,-0.04458906,0.017576683,-0.031055829,-0.007776984,0.05936415,-0.015313389,-0.017587721,-0.09574347,-0.06115853,0.026216667,0.010458234,-0.020108066,0.029718215,-0.028119994,-0.0414985,0.04185156,-0.07526272,0.022944007,0.026391847,-0.064453736,0.005966703,-0.018451273,0.018949872,0.0009992187,-0.030196229,0.00025255393,0.054332547,0.0011353679,0.0050545237,0.0011137227,0.015872441,-0.03168491,0.025560189,-0.012055062,-0.0020171076,-0.018822365,-0.060327478,-0.004160906,-0.0021132955,-0.031623423,-0.0416912,0.0057439995,0.0015058527,-0.011337791,-0.059317518,0.011267877,0.0030178875,-0.059539218,-0.027803304,0.039271835,-0.07271301,-0.01663598,-0.025824253,-0.00021426995,-0.060878284,-0.009418094,-0.029268362,0.011269606,0.010694739,0.09590423,-0.010932577,0.0041021644,0.06660056,0.0076001,0.020660348,-0.002642452,-0.0025190287,-0.009304982,-0.011995833,-0.020273177,0.030183537,-0.054498922,-0.020039957,0.022200251,0.124300696,0.027501222,-0.06120205,0.04149356,-0.021574274,-0.006056265,0.00486367,0.037746217,0.043780033,-0.061848383,0.014976497,0.050711803,-0.011405019,0.039812375,-0.023844153,0.0357913,-0.015792804,-0.08733029,0.032675687,-0.037791226,0.02584469,-0.015935635,0.03857301,0.032331266,-0.010746165,-0.002192976,0.03683596,0.037582576,-0.039596,0.037896365,-0.07491355,-0.05155972,0.059467625,-0.00849652,-0.013118275,0.036356814,0.053797275,-0.016812317,0.054659054,-0.07958774,-0.02420609,-0.07404675,-0.051083893,0.014905556,0.009965263,-0.06908521,0.017215088,-0.023677247,-0.042766437,0.02415523,0.018698702,-0.0038194992,-0.011756432,-0.017574858,-0.008075632,0.01589666,0.027743323,-0.020626785,0.024680449,0.02972493,-0.057075527,-0.03534331,0.005735777,-0.00991687,0.07863808,0.062968984,-0.019439843,0.0032373061,0.050571546,-0.024379415,0.017431976,-0.079206444,-0.004755205,0.056689158,0.04054219,0.02266517,0.04880266,0.051074136,-0.036878888,-0.016659368,0.021388547,-0.05665779,0.04790321,-4.0154788e-05,0.044182174,-0.0023220386,-0.017448163,0.057779085,0.05847918,-0.03957582,-0.00058552914,0.013313669,0.022489343,-0.049293548,0.057144195,0.024411853,-0.016096385,0.05417373,0.036185976,0.022869814,-0.026034571,0.036897894,0.015593791,-0.02532362,0.0345189,-0.037123334,0.057800632,0.0055097053,0.022386124,-0.019620653,0.01989525,0.055550702,-0.024937589,0.019776383,-0.072343536,0.016441913,0.015389936,0.0015551503,0.029121544,-0.06800412,0.010423998,-0.0117942225,-0.012413265,0.012772532,-0.01027528,0.006639657,-0.0014531428,0.010074513,0.030013349,-0.04798746,0.020070791,0.016869174,-0.027102802,0.0057233935,-0.029913694,-0.016377775,0.014302369,0.001924525,-0.025297578,-0.004312046,-0.02194015,0.0047989455,-0.04377225,-0.017012266,-0.02374911,-0.0037242805,0.01071668,-0.026363473,0.02326286,-0.04689371,0.051466912,0.0037040333,0.005296629,-0.12175678,0.019929972,0.023130499,0.02162048,-0.007098422,-0.026384123,-0.050148454,0.029640898,-0.052832913,0.024290256,-0.002404558,-0.048713673,-0.009143067,-0.018298538,0.034209397,-0.009355791,0.048373375,-0.008000619,0.03417713,0.024247117,-0.010694751,0.042859487,-0.034191065,-0.046743713,0.018566975,-0.004338437,0.048431337,-0.10784507,0.040075663,0.048483077,-0.053408902,-0.024767915,0.036964007,0.03335275,-0.022532638,-0.00079337746,0.05798602,0.012258158,-0.056719746,0.054460976,0.045800697,-0.03902981,-0.03050945,-0.04753965,0.0035714617,-0.03460124,0.0022992028,-0.028737316,0.035496965,0.0447447,-0.037237003,0.12520503,-0.015934832,-0.021023368,-0.028476894,0.015220356,0.008353998,-0.016597964,0.02136049,0.00070273696,-0.019300444,-0.031087855,0.025993345,-0.019082403,-0.030913668,0.033578634,-0.042837285,0.012936323,-0.04314817,0.05888743,-0.009183635,0.02638198,-0.038212188,0.010044286,-0.11836807,-0.06494228,0.04217709,-0.032634567,-0.0174742,0.030562896,-0.024949228,-0.0005448304,-0.011344378,0.0031273158,-0.017544204,0.009879216,-0.055376526,0.0430389,-0.015390054,-0.02284082,-0.03162661,0.049923755,-0.007069523,-0.041686546,0.054898344,-0.004244729,0.053971507,0.024915189,0.008257412,0.0016813054,-0.04336153,0.0054229493,-0.03762892,0.018298732,0.004855986,0.008379091,-0.0029416215,0.03207067,-0.014368643,-0.025525475,0.06480624,-0.069307335,0.031211149,0.038594805,0.0039179805,0.035788283,0.023152811,-0.010469352,-0.01525911,-0.0057256888,-0.043956187,-0.05310596,0.0076831966,0.007895808,0.035446383,0.030712055,-0.0017840288,0.011429003,0.027422547,-0.18490511,0.016110778,-0.008094019,-0.047397558,-0.007305394,0.021406384,0.01787705,-0.02721511,0.0021938493,0.039204735,0.029036328,-0.044544064,0.027376993,-0.030909885,-0.037178975,-0.005225996,0.015306101,-0.020092402,0.019229822,0.013042238,-0.005402455,0.05365587,-0.037114013,-0.02249726,-0.028526748,-0.026350984,-3.2233496e-05,0.009274287,0.012959367,0.015050203,0.026093235,-0.005984242,0.040552545,0.011598502,-0.021823961,-0.01256148,-0.010716291,-0.0004877652,-0.10404828,0.037174642,0.035296094,-0.018645104,-0.048983958,0.017650275,0.0021274295,0.044126347,0.025991123,0.035054017,-0.017482722,-0.009836557,0.016776133,0.016972657,-0.09142743,0.010003648,-0.0032673301,0.06277446,0.025247386,0.022512367,0.03409412,-0.024529343,0.041305497,0.06543058,-0.006081662,-0.004444869,-0.008199003,0.012094722,0.05139724,-0.026223823,-0.004220657,0.00012071224,0.048300654,-0.046175733,-0.008796782,-0.01257794,0.037047498,-0.033472832,0.014913876,-0.01959564,-0.06020127,0.0026384601,-0.058079544,-0.019256802,-0.0052120383,0.04414785,-0.034168422,-0.0418819,-0.066872686,0.01816047,0.039825547,0.028765872,-0.018933777,-0.034413658,-0.002762779,-0.0018078719,0.025990617,-0.022323398,-0.061891027,0.018537715,-0.017630417,-0.023042243,0.024537414,0.010894706,-0.031894386,0.032090273,0.054262217,-0.04620337,-0.09965418,0.020877618,-0.03489639,-0.04018612,0.06383621,0.03565254,0.054654412,-0.022892842,-0.0027761234,0.0010259546,0.019980676,-0.03218896,-0.026182307,-0.042763002,-0.0074640866,-0.019033847,-0.0028095865,0.018759092,0.0147461,0.019371936,-0.049813107,0.057362128,0.0054589347,0.018052824,0.016816087,-0.064604566,0.03080498,-0.003626405,-0.0067250454,0.03135205,0.017986784,-0.012689799,0.030520942,0.0194321,0.062142365,-0.04586833,-0.026691379,0.04076765,-0.014948754,0.012980962,0.000341664,0.0034237301,0.0061327447,-0.035449155,-0.01806622,-0.0880895,0.0072377967,-0.014344589,-0.01070182,0.023736399,0.016119583,0.034783516,0.019337486,0.029162493,-0.011298732,-0.05097148,-0.021137023,0.0020952832,-0.004312209,-0.00041121445,0.0002560612,-0.03233625,0.017392622,0.022550203,-0.0332454,0.066107444,0.043994788,0.024340862,0.009450728,-0.024332734,0.04368603,-0.009236842,0.0009251312,0.03735006]
10	sessions	Table: sessions\nDescription: session การ login ของ user ใช้สำหรับ authentication ระบบ session-based\nColumns:\n  id         VARCHAR(255) PRIMARY KEY,                                -- session token สุ่มสร้าง ใช้เป็น cookie\n  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,   -- FK → users: user เจ้าของ session\n  expires_at TIMESTAMPTZ NOT NULL,                                   -- วันหมดอายุของ session\n  created_at TIMESTAMPTZ NOT NULL   	[0.022272054,0.019350922,-0.01984081,0.036244247,0.018737784,-0.04720345,-0.030666437,-0.009871223,0.05437756,0.038813513,0.016729256,0.023829078,0.12577467,0.04789078,-0.00791622,-0.025729423,-0.012584821,-0.019574787,0.002825606,-0.008864605,0.0310733,-0.033313982,-0.0061764675,-0.016131705,0.025494331,-0.04276699,0.0008080054,-0.005005638,-0.051616766,0.019630603,0.016083615,-0.012458871,-0.015972327,0.057225663,0.024671517,0.014740041,-0.009836201,-0.005801532,0.018971108,-0.0069758478,0.010428003,0.009910638,0.046356462,-0.05762203,0.009635873,-0.017697934,0.060095355,0.038303986,-0.013709621,-0.036766503,0.034516428,-0.0038328627,0.042618956,0.011248589,-0.03895342,-0.039341126,0.02211947,0.036264416,-0.037858788,0.019873412,-0.012140292,0.048582766,0.0005105855,0.013296349,0.02489217,-0.009817523,-0.003139639,-0.02090888,-0.029453134,-0.011894002,-0.02423309,0.0039314884,0.12363559,-0.02751241,-0.008447792,0.0111808395,-0.036579415,0.022540428,0.018781584,-0.005321082,0.07427192,0.042173807,0.010367492,0.00565748,-0.011815758,0.006701811,-0.020995695,0.044757754,0.060665313,0.03639415,0.0141912615,-0.040676218,-0.037678026,0.039868258,0.023016725,0.033324298,-0.0008848095,-0.0016732595,0.057304,-0.046630297,-0.0380939,-0.09627558,-0.032007664,-0.041984804,-0.08149571,-0.023538928,-0.01870241,-0.065129004,0.054749053,-0.01698216,0.0025330728,0.01086514,0.00012942345,-0.04664242,0.060971458,-0.018062878,0.059507698,-0.07053296,0.01945087,-0.06929378,-0.032492027,0.0020168857,-0.007978507,-0.029064298,0.055481575,-0.05264865,0.0019540563,-0.013985552,0.025941376,-0.036376897,-0.03920022,-0.065085925,0.0062011066,-0.008899196,-0.010265221,0.059691593,0.032289483,0.006092999,-0.021101048,0.0031755592,0.037518285,-0.027099203,0.027641984,0.062503465,0.023449747,-0.08309346,0.010219483,0.010888365,-0.03520443,0.025248876,0.024487276,-0.046638153,-0.019826403,-0.0068807523,0.025451776,-0.006242913,-0.04193013,0.0024831663,-0.004550582,0.038192034,0.017067567,0.0023245458,0.015705146,-0.02523279,0.027668051,0.008877507,0.001064289,0.0054873605,-0.037091147,0.009687012,0.0009380449,-0.04847625,-0.06470395,0.03398244,-0.037762273,-0.019670554,-0.021216653,-0.042510778,-0.030245429,-0.06118375,-0.059514187,-0.017329365,-0.061993845,0.023164121,-0.007785279,-0.014057801,-0.032106012,-0.014750845,0.053562175,-0.009667637,-0.00017368236,0.07456423,-0.008306301,0.023751391,0.03326586,0.02968233,0.022077719,0.0285756,-0.02265959,-0.052482385,0.0047614756,-0.0066102934,0.03291692,0.02883874,0.026733175,-0.056484822,-0.010571134,0.044559944,0.030112216,0.022270173,-0.03664314,0.03553702,-0.025981475,0.038811997,-0.0032399346,-0.039198916,0.02219055,0.010070147,-0.007932943,0.03047446,0.018147333,-0.035662618,0.073002696,0.048619524,-0.029530713,0.014151845,0.016012695,-0.008635351,0.022324786,0.057389136,0.07004423,0.07588472,-0.015505699,0.021481715,-0.015925279,-0.03232474,0.025759531,-0.016800778,-0.015456243,-0.110228576,-0.028347129,0.02975572,-0.0036461083,-0.032943074,0.033714075,-0.010749059,-0.050244283,0.031020522,-0.04541172,0.007969636,0.027870383,-0.036125813,0.012932594,-0.016644679,0.0009803725,0.013784517,-0.020467456,0.002173402,0.016058901,0.020330902,0.011014256,-0.016441612,-0.020967253,-0.0562763,0.005767312,-0.0031414286,0.00352371,-0.028462788,-0.03572844,0.010886241,0.014398556,-0.034221847,-0.037588015,0.023396056,0.034195855,-0.018510923,-0.0628473,0.031185739,-0.010579087,-0.034179315,-0.034873907,0.02892213,-0.06676892,-0.032329593,-0.042804245,-0.0056797275,-0.041383866,-0.03397758,-0.05426014,0.011950111,0.0037302345,0.069979675,-0.0053163827,0.00801551,0.029447718,0.007319195,0.028147852,0.029058417,0.0022313602,-0.018152883,-0.025693515,-0.013091588,0.02752156,-0.049816072,0.006279936,0.029968703,0.12221759,0.007091172,-0.03186959,0.039126143,-0.020460393,-0.021586679,-0.025169373,0.07272636,0.028333211,-0.063879706,0.005770437,0.07415508,-0.026847245,0.023970556,-0.068293326,0.015872147,-0.014038882,-0.065938726,0.039401144,-0.031756535,0.026368726,-0.015943505,0.046868354,0.01930013,-0.021140467,0.027376208,0.0053926343,0.051733736,-0.044608746,0.0241818,-0.050403308,-0.053912222,0.07744211,0.021510161,-0.016446838,0.04255992,0.04904421,-0.007456564,0.037720133,-0.066998795,-0.021372182,-0.05558822,-0.038342778,0.0120104365,0.04806833,-0.05104133,0.01717918,0.009656281,-0.03159843,0.017990341,-0.011700286,-0.0130981,-0.020596635,-0.0034089207,-0.011203121,0.04248219,0.0048106564,0.01872718,0.011498817,0.01655939,-0.08318717,-0.038552564,0.007253134,0.02393214,0.09800493,0.032030303,-0.050374992,-0.015994804,0.024938785,-0.0428659,0.027900139,-0.097168,-0.006448787,-0.00023948574,0.01765904,0.07847073,0.030542508,0.011162162,-0.031183459,0.025731243,0.025355259,-0.039316017,0.04081275,-0.01668537,0.03777432,0.021338494,-0.015115909,0.04627301,0.042410407,-0.002374358,0.029904407,-0.021261828,0.00838662,-0.041414574,0.07297705,0.018168379,-0.022434253,0.06636044,0.07476798,0.04534032,-0.008544537,0.030237807,0.029062508,-0.036760062,0.03258423,-0.026685983,0.022638984,0.0017773227,0.005663898,-0.021678496,0.024445679,0.04810142,0.0027487087,0.035936948,-0.050686657,0.015157628,0.026625156,0.01701109,0.014948038,-0.0796994,-0.015791068,-0.031148095,-0.015249988,-0.008486868,-0.030922525,0.0046014725,0.015029321,0.0035336378,0.014661117,-0.035755754,0.029219579,0.0060428726,-0.06140711,0.012045836,0.0039828154,-0.030816307,0.00904736,-0.008329565,0.0028344472,-0.0146182515,-0.04357438,-0.0046844026,-0.033881582,-0.018758502,0.007738538,-0.0035871735,-0.01612818,-0.014456533,0.040968552,-0.024908166,0.043965656,-0.034092966,0.033667874,-0.10455542,0.042255104,0.060491152,-0.019879634,0.013694317,-0.037713483,-0.04790022,0.043216437,-0.04247009,0.002589733,-0.004616204,-0.038707364,-0.023430506,0.0045780395,0.039192975,-0.0048368736,0.037456214,-0.0035574466,0.014470716,0.022192324,-0.0058991867,0.045667302,-0.015601268,-0.05012362,-0.012149466,0.012091747,0.045826666,-0.07923393,0.03473281,0.0383395,-0.027264208,-0.037252802,0.055272646,0.021785421,-0.014444666,-0.024584983,0.04539274,0.0009698393,-0.059190605,0.045593042,0.017631337,-0.004814127,-0.00080928794,-0.02966399,-0.0037816623,-0.047036756,0.008092484,-0.021399062,0.017943589,0.039440606,-0.030580007,0.12343531,-0.010452076,-0.02733244,-0.017524429,0.030249836,0.010137832,-0.018632323,0.032678623,0.028923057,-0.021945702,-0.034129675,0.014092686,-0.04407302,-0.0009442635,0.009111041,-0.06568205,0.01429491,-0.024596367,0.03550852,-0.049576014,0.03144949,-0.039695706,0.05349496,-0.09510526,-0.05276498,0.00392294,-0.007866736,-0.01858105,0.03322738,-0.04710647,0.0061393506,-0.011306337,0.015036111,-0.042334642,0.009768506,-0.030557245,0.024334583,-0.03013603,-0.010521628,-0.023308849,0.04851599,-0.0004329044,-0.031534977,0.05087607,-0.04527961,0.055658326,0.028682733,0.017452573,-0.0022291956,-0.024371019,0.0142555,-0.030541847,-0.008273044,0.040089946,-0.007222909,0.03878889,0.01268984,-0.022800282,-0.022083351,0.07197568,-0.09413895,0.032775145,0.031748205,6.5354136e-05,0.050212935,0.05704537,-0.0071478398,-0.026044995,4.0144176e-05,-0.05296511,-0.0796029,-0.0391661,0.0154047785,0.025656054,0.041535366,0.0019720686,0.041246258,-0.0052147694,-0.1915575,-0.0050729415,-0.007026346,-0.032430235,-0.0018454925,0.026233435,0.039251946,-0.0075613675,-0.0070799286,0.028224874,0.036515824,-0.04213983,0.020972358,0.015055789,-0.039100602,-0.0044138003,-0.012112072,-0.02123463,0.032450564,-0.0020601456,0.012482765,0.05872964,-0.039541215,0.011943666,-0.048460685,0.0038475818,0.005935971,0.01835369,0.024297407,0.0066930843,0.02604364,-0.0010623495,0.018380148,0.010144302,-0.0275714,-0.027814934,-0.02189587,0.0076235696,-0.0612489,0.05747846,0.009375866,-0.014582381,-0.0324743,0.012961771,-0.009369198,0.051307924,0.030192181,0.01829594,-0.026595253,0.0019313298,-0.012326896,0.009510906,-0.090012,0.017208911,0.0024185353,0.051594365,0.024657533,0.01492961,0.067994736,-0.017735621,0.05227828,0.07289668,-0.04249157,0.0075893067,-0.0146610765,0.017844789,0.06335466,-0.036288284,-0.03780266,0.0080017615,0.041511163,-0.047470454,-0.018254792,0.011217676,0.031332344,-0.037377685,0.020976689,0.0026657016,-0.066632025,0.0061966744,0.0009469579,-0.017485594,-0.01752833,0.042000562,-0.039473597,-0.014679223,-0.055719238,0.034942027,0.04068862,0.0053391624,-0.02446254,-0.06332743,-0.010098359,0.013942846,7.4465606e-05,-0.027897418,-0.024035875,0.0021506778,-0.00097346504,-0.03309048,0.010626594,-0.034928564,-0.040586755,0.0014551579,0.0518597,-0.04232892,-0.116879,0.029844783,-0.039821815,-0.0506288,0.039491795,0.042969454,0.03797966,-0.019925874,0.026693285,0.0047333864,0.021452384,-0.04012344,-0.035238143,-0.05771378,-0.004069755,-0.01756476,0.01905684,-0.014568571,0.023136338,0.014618485,-0.035427958,0.044060223,0.008701049,0.038688082,0.023550408,-0.05293421,0.046450794,-0.0065404885,-0.030163689,0.04621048,0.009817577,-0.015110825,0.03968624,0.020683799,0.05803795,-0.080762826,-0.0090350965,0.056616705,0.011183338,0.012176874,0.017718041,-0.001421671,-0.0051013557,-0.022400696,0.021481203,-0.06832371,0.019761637,-0.019868627,-0.026921736,0.009211743,0.023616636,0.0069000376,0.0010921133,0.013661421,-0.016337398,-0.042709365,-0.015711788,0.033609986,0.005962704,0.007232122,-0.013610591,-0.015965646,0.03493194,0.024846826,-0.04685833,0.027686397,0.01484077,0.012910745,0.025789697,-0.0057260855,0.07071544,0.01845138,-0.009583279,0.04363142]
11	task_assignees	Table: task_assignees\nDescription: junction table เชื่อม user กับ task task หนึ่งมี assignee ได้หลายคน\nColumns:\n  id         UUID PRIMARY KEY,                                              -- รหัส\n  team_id    UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,           -- FK → teams\n  task_id    UUID NOT NULL REFERENCES project_tasks(id) ON DELETE CASCADE,  -- FK → project_tasks: task ที่ assign\n  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,          -- FK → users: user ที่รับผิดชอบ task\n  created_at TIMESTAMPTZ NOT NULL                                           -- วันที่ assign\n  -- UNIQUE (task_id, user_id): assign user คนเดียวกันซ้ำไม่ได้\n	[0.00054393767,0.03513488,-0.016343284,0.015623642,0.021932874,-0.0031217714,-0.026639562,-0.026529148,0.04662499,0.0122943,0.031225257,0.015807472,0.10524193,0.043185346,-0.022754097,-0.012511894,0.0041576433,-0.012629899,0.021917433,-0.012898682,0.023053128,-0.043087564,0.012462034,-0.0014733246,0.026994755,-0.021951934,0.013604391,0.0026005842,-0.058746364,0.013564991,0.037138283,-0.01844313,-0.009201048,0.023640472,0.015533897,-0.011843747,-0.010157647,-0.01345403,-0.0030677407,0.0070294742,0.038746618,0.009222999,0.018878682,-0.016321063,0.023637984,-0.008049899,0.044136457,0.02221009,-0.017792713,-0.0065170154,0.017041458,0.0050328407,0.037586454,0.024049591,-0.0626935,-0.029530691,0.047387786,0.026210712,-0.03131293,0.031785782,0.022024464,0.0367833,0.0019631844,0.035822894,0.026883509,-0.003465876,0.017130755,-0.017098308,-0.039072704,-0.02554941,-0.00950488,-0.0009321357,0.086929284,-0.0388889,-0.020513969,-0.0024229423,-0.040527984,0.020467576,0.026527625,-0.0136241475,0.065643206,0.028344331,0.014203435,0.010623679,-0.005831035,-0.019345079,-0.0019731007,0.041934855,0.044539835,0.048066493,0.05142826,-0.045126606,-0.04443957,0.04012146,0.016538365,0.026487647,-0.009194192,0.011117862,0.023980401,-0.025472263,-0.0013393094,-0.08657842,-0.030066473,-0.0283876,-0.09384311,-0.035002884,-0.006831831,-0.044013407,0.042563442,-0.010087618,0.0079135215,0.000679432,0.005643976,-0.03208456,0.038023584,-0.047796454,0.04820959,-0.06350178,0.0055887,-0.057269875,-0.04931406,0.016556287,-0.02740289,0.00085272663,0.056708477,-0.03393097,0.0018919171,-0.00961367,0.038190182,-0.04461883,-0.01738597,-0.064413786,0.03201731,0.011520678,-0.02625492,0.048575874,0.022918401,0.0339123,-0.016528917,0.0068699997,0.008872656,-0.020348346,0.008539244,0.035690807,0.011969285,-0.070025384,0.0027711613,0.029765729,-0.024095984,-0.0014949566,0.035516206,-0.052442398,-0.027198117,-0.026451355,0.039140508,-0.0099865785,-0.058475763,-0.011120991,-0.018006181,0.03904267,0.016276421,-0.008289387,0.025889333,-0.032077115,0.018228417,0.024705403,-0.018593222,0.028727964,-0.049125064,0.01279496,0.015700728,-0.058156718,-0.081947625,0.03198764,-0.052098352,-0.03476877,-0.027321326,-0.029512703,-0.0373768,-0.04484794,-0.073492885,0.01161143,-0.009245669,0.027812624,-0.0035292555,-0.016259944,-0.009093368,-0.008604717,0.06844816,0.006877518,-0.00037336044,0.08076965,0.025489572,0.034782436,0.033877626,0.0063988753,0.012628391,-0.003281286,0.02837597,-0.027505245,0.004895503,-0.008731333,0.04150211,0.022083512,0.025642328,-0.060633164,0.00017772614,0.061203185,0.030482408,0.018009817,-0.018262923,0.009165437,-0.037509583,0.04203432,-0.015595029,-0.042551976,0.019433348,0.012844424,-0.024523696,0.05064006,0.0005554182,-0.023700995,0.043711036,0.0314329,0.0051047746,0.019048912,0.040994372,-7.9189624e-05,0.011299621,0.03617649,0.07233952,0.091197126,-0.047180336,0.0169164,0.014612486,-0.0030134853,0.03206721,-0.022187706,-0.018230319,-0.11854611,-0.03753593,0.012121534,0.013882921,-0.032823108,0.031575523,-0.01767758,-0.019849112,0.044391826,-0.04304384,0.039772887,0.021714706,-0.042476397,0.019093959,-0.048086543,0.007845854,-0.0008477576,-0.04527675,0.00557545,0.03654174,0.013221736,0.0055418015,0.0034878864,0.0018740852,-0.035047293,0.024816014,0.0068634893,0.03196172,-0.030659754,-0.058067545,0.021379191,0.0042641317,-0.015565206,-0.039646953,0.020208873,0.019418096,-0.016761968,-0.064533934,0.03819174,-0.025520355,-0.037632555,-0.02562962,0.063191876,-0.08142018,-0.04924409,-0.024516864,-0.030107703,-0.053253077,-0.009919859,-0.043443423,0.0066388003,0.026712291,0.07008367,-0.006187738,0.014608888,0.053881492,0.018715592,0.035617463,0.022865217,-0.01802509,-0.009028992,-0.02912287,-0.029804775,0.03960252,-0.06404534,-0.014400174,0.015431554,0.11625419,0.0028433183,-0.053263504,0.044013534,-0.03190607,-0.014914277,-0.040485762,0.039352167,0.036021072,-0.022340758,-0.004141133,0.057878118,-0.0060817446,0.023676412,-0.022709444,0.031103252,-0.005873169,-0.0746332,0.04069476,-0.05223276,0.02840925,-0.011665668,0.0735687,0.032777842,-0.010023851,-0.00393922,-0.000354264,0.043463055,-0.01418106,0.047519486,-0.07134617,-0.06616745,0.04775788,0.0009350672,-0.006850498,0.029223919,0.023746384,-0.012381233,0.06490429,-0.06819265,-0.029480709,-0.060139585,-0.061303012,0.023269553,0.023634274,-0.055437416,0.02048698,-0.01441439,-0.0103326095,0.009570919,0.01870919,-0.009176855,-0.033290483,-0.016293567,-0.014834724,0.025909213,0.009837596,-0.01094429,0.006135871,0.021373285,-0.047242835,-0.035573933,0.0135195935,-6.379743e-05,0.11805881,0.057413783,-0.03092695,-0.017577155,0.03261426,-0.023196215,0.022427626,-0.09663969,-0.017022518,0.028556919,0.041825384,0.04583193,0.010123946,0.04409789,-0.035807323,-0.011012777,0.036861718,-0.048192352,0.041341525,-0.009253787,0.034797605,0.024163332,-0.013812071,0.03899273,0.038783215,-0.026297813,0.04047824,-0.003991774,0.0039044677,-0.027515689,0.065772034,0.030609252,-0.003471057,0.048810028,0.049689952,0.021174947,-0.012142786,0.029917972,0.03060179,-0.040143307,0.051886074,-0.059162263,0.044846896,0.014091297,0.017433222,-0.016616255,0.02256206,0.041727513,-0.030577702,0.0066428743,-0.040998776,-0.0083123045,0.04177753,0.010856487,0.015554992,-0.08734066,-0.008669693,-0.019941667,-0.00039692983,0.0008840643,-0.012938099,-0.0022966943,0.025243128,0.01833491,0.022165619,-0.04884907,0.013119108,-0.0020588066,-0.040540963,-0.012048356,0.0029207077,-0.032842517,0.0071955523,-0.029100683,-0.019599304,-0.021909231,-0.026382191,0.010986633,-0.027759138,-0.012355843,-0.0061269575,0.006938163,0.017571628,-0.0012002706,0.018914886,-0.06685882,0.031239081,-0.015742691,0.025764316,-0.12296015,0.052864354,0.043228984,-0.02679008,-0.04153089,-0.04406753,-0.08239569,0.020943236,-0.071564436,0.061453115,-0.0021455395,-0.031264592,-0.008329588,0.0020655654,0.039250992,0.024317842,0.041812018,-0.013350117,0.00746207,0.031676922,-0.007772651,0.03515345,-0.030489609,-0.016657002,-0.015424675,0.0048953933,0.036998745,-0.0821612,0.036650192,0.052435886,-0.030922282,-0.034087002,0.037290756,0.040204138,-0.013915604,-0.016962068,0.02213082,-0.0047879047,-0.050675623,0.062181156,0.034578297,0.0042603705,-0.036809687,-0.033640932,-0.011116336,-0.022055108,0.0021441313,-0.027163472,0.028683772,0.03668261,-0.047338646,0.11306554,-0.0051021157,-0.041515153,-0.0057992777,0.020541115,0.01931516,-0.01198628,0.022068704,0.016459553,-0.008500478,-0.025006942,0.0057198564,-0.033114668,-0.018490119,0.009529577,-0.05855253,0.00798964,-0.034647193,0.03972806,-0.027256474,0.007433579,-0.06029541,0.033848416,-0.09463906,-0.08511115,0.06618392,-8.242313e-05,-0.030506093,0.018920373,-0.029009074,4.841422e-05,-0.013109902,0.03321674,-0.026993781,0.020418154,-0.026269635,0.005342359,-0.034892105,0.017866753,0.008267208,0.039474186,-0.009481937,-0.0015584922,0.055359967,-0.026881648,0.03985714,0.0113580525,-0.0019947405,-0.0058456925,-0.026131283,0.020255297,-0.014428145,0.0032175817,0.011995666,-0.021172276,-0.013045749,0.03854019,-0.037685398,-0.028783377,0.05817042,-0.066262856,0.021228306,0.0509145,-0.012711097,0.05889751,0.029897133,0.0013390906,-0.003699183,-0.0005970355,-0.051649086,-0.06379353,-0.027474035,-0.009877114,0.041666955,0.06278808,0.0067732683,0.0256946,0.0070046103,-0.20333982,0.0046437304,-0.0087192925,-0.040381763,-0.0030669714,0.015835818,0.01594015,-0.015136193,0.008320034,-0.0042111385,0.03447521,-0.03637514,0.0030098702,-0.017306224,-0.049415782,0.0067055044,-0.008655398,-0.03378144,0.014368673,0.049340136,0.012022677,0.065060504,-0.03674437,-0.01673839,-0.026186688,0.0035953189,-0.011447179,0.036509026,0.01702365,-0.008980071,0.017921615,-0.00037414717,0.042528164,0.008850318,-0.006538517,-0.051406827,0.0051379562,0.00647504,-0.07065379,0.053318214,0.008576359,0.0020624062,-0.057324078,0.018171972,-0.0049352003,0.04015276,0.038448464,0.03942129,-0.037920214,-0.025206381,-0.01321315,0.0037079626,-0.08452172,0.02752252,0.002431475,0.090951726,0.031451676,0.023110818,0.043117262,-0.02610837,0.052958857,0.037462644,-0.024827573,0.012792639,-0.02974548,0.00913893,0.07703673,-0.03213859,-0.030812979,-0.0004699426,0.049923956,-0.040376667,-0.024133757,0.003350717,0.029387785,-0.02954739,0.0012339228,-0.03270641,-0.07970016,0.009975349,-0.034973666,-0.040383317,-0.0059956145,0.039375618,-0.042250734,-0.014469613,-0.033872183,0.017798727,0.039893985,0.037582893,-0.012114008,-0.067273945,-0.012437414,0.0011436112,0.018277338,-0.04006598,-0.022388242,0.041770276,0.0034293586,-0.01411415,0.022881243,0.010149432,-0.020596903,0.028204292,0.027051156,-0.035238333,-0.12959059,0.006255613,-0.042469937,-0.055577077,0.056043945,0.051240515,0.040252857,-0.018239167,-0.00014696698,0.02231397,0.011243893,-0.018407179,-0.019007193,-0.017307429,-0.014702251,-0.036868215,-0.011716872,-0.010008186,0.027263753,0.008351369,-0.05207996,0.051716447,0.012163215,0.024324331,0.0053225905,-0.070050865,0.034610074,-0.028094241,-0.034880307,0.025105143,0.018035622,-0.010191646,0.046864413,-0.0025435034,0.043461673,-0.070438124,-0.036123086,0.05410623,-0.0023550405,0.0038294937,-0.023593951,-0.0045256927,0.023408605,-0.017621662,-0.0058206976,-0.098421864,0.01907221,-0.01169914,-0.01098091,0.021394249,0.017167963,0.045765605,0.009338429,0.026417622,-0.045825616,-0.046876457,-0.0054231617,0.010563536,-0.0024568308,0.036635086,-0.006708177,-0.03845228,0.0029379055,0.022742242,-0.035648216,0.06365991,0.021210218,0.028251426,0.036002304,-0.014489692,0.043106947,-0.014381788,-0.041291308,0.03229033]
12	team_membership	Table: team_memberships\nDescription: เชื่อม user กับ team พร้อมกำหนด role ของ user ในแต่ละ team user 1 คนมีได้ 1 role ต่อ team\nColumns:\n  id         UUID PRIMARY KEY,                                    -- รหัส membership\n  team_id    UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE, -- FK → teams: team ที่ user เป็นสมาชิก\n  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,  -- FK → users: user ที่เป็นสมาชิก\n  role       TEXT NOT NULL,                                        -- OWNER / ADMIN / MEMBER / VIEWER / BILLING\n  invited_at TIMESTAMPTZ,                                          -- เวลาที่ได้รับ invitation (NULL = ไม่ได้ถูก invite)\n  joined_at  TIMESTAMPTZ NOT NULL,                                 -- เวลาที่เข้าร่วม team จริง\n  created_at TIMESTAMPTZ NOT NULL                                  -- วันที่สร้าง record\n  -- UNIQUE (team_id, user_id): user อยู่ใน team เดียวกันได้แค่ครั้งเดียว\n	[0.00857707,0.020671027,-0.025508318,0.033556804,0.010601051,-0.037541874,-0.032854043,-0.029941283,0.03694112,0.0018501192,0.022285301,0.012203558,0.12530105,0.04635973,-0.024006736,-0.0043419744,-0.017619235,-0.013289816,0.01942913,-0.029663336,0.049556553,-0.04184494,0.043469127,0.0007623026,0.031478625,-0.03988345,-0.0031957326,-0.017977476,-0.03493525,0.02068679,0.035771165,-0.02234939,-0.021510096,0.03498121,0.01208679,0.020600816,0.0045623807,-0.0077768997,0.0055028955,-0.019337526,0.033373527,0.00904069,0.02779146,-0.033004027,0.027288003,-0.014922825,0.045694668,0.03141193,-0.028269935,-0.01748113,0.02146894,0.013872506,0.04199678,0.0095385155,-0.040317878,-0.028823216,0.028909493,0.048398525,-0.03478035,0.019199971,0.002285416,0.048065238,0.00045074476,0.019576596,0.021973707,-0.003735054,-0.0073862774,-0.037035286,-0.044846013,-0.022264749,-0.0050336467,0.008841932,0.09892752,-0.0070100077,-0.023236686,-0.010831262,-0.050593764,0.01607797,0.018344123,-0.013295002,0.061494883,0.0039320467,0.025645453,0.023210607,-0.021243682,-0.007638281,-0.009708577,0.05043257,0.03217307,0.03129769,0.018341472,-0.04063972,-0.058506504,0.013754782,0.037421945,0.027847394,-0.014748197,0.009503532,0.05932184,-0.048518006,0.009117134,-0.08710874,-0.038239114,-0.03305799,-0.078004174,-0.038570113,-0.0068820966,-0.040104873,0.045339566,-0.023187831,0.00036811517,0.0014209349,0.009191699,-0.06249846,0.045818686,-0.05235104,0.04639529,-0.054743197,0.01849538,-0.05457221,-0.04248271,0.031142939,-0.012389876,-0.0047163866,0.040443376,-0.030933894,0.008042235,-0.0067245164,0.020599188,-0.03804316,-0.03546967,-0.04417831,0.0101890825,0.0064636203,-0.015633836,0.049461447,0.025187278,-0.014594896,-0.0018688163,0.0005380484,0.038748797,-0.038180094,0.00947744,0.023686634,0.013273282,-0.07084097,-0.007875002,0.013545536,-0.0314492,0.011108552,0.028736541,-0.052539706,-0.038602397,-0.013778935,0.037408073,0.0031328788,-0.029203482,-0.02125436,0.02239932,0.040816456,0.039492518,-0.01691026,0.027823819,-0.026417047,0.039908994,0.023249738,-0.024650581,0.0073387185,-0.040244713,0.0014500296,-0.0062771244,-0.053502377,-0.0817637,0.042316306,-0.02807587,-0.034442723,-0.021666288,-0.03252789,-0.04328086,-0.039222118,-0.07353142,0.004782852,-0.031225871,0.02563678,-0.023863954,-0.016948977,-0.02238696,-0.032519884,0.07100027,0.02291485,-0.014519963,0.07676391,0.0061641135,0.029567745,0.029054185,-0.0051074536,0.024825476,0.029611059,0.013854188,-0.032855198,0.029368043,0.0021253785,0.05731749,0.042967685,0.030361427,-0.06110395,-0.006927702,0.036769375,0.022762876,-0.0020043214,-0.01645382,0.025028339,-0.012221347,0.048602354,-0.038387425,-0.034131106,0.026978122,0.023836266,-0.038145673,0.040651105,-0.0030652718,-0.028326862,0.07301269,0.02539199,-0.026781727,0.01871133,0.021059847,-6.483576e-05,0.04379293,0.037610263,0.06800962,0.092257544,-0.024941044,0.036516454,-0.0074076103,-0.01575079,0.0078031584,-0.012609902,-0.017958594,-0.1103972,-0.024897592,0.021511417,0.009531765,-0.012728848,0.019122932,-0.015730925,-0.028278528,0.033395197,-0.050603766,-0.010676708,0.04960206,-0.027321842,-0.010847898,-0.0420869,0.008104892,0.01782004,-0.03317188,0.025851337,0.041472696,0.0034725827,0.023197401,-0.0026812807,-0.003942458,-0.040384084,0.022863457,0.009227497,0.015381082,-0.011814678,-0.070245415,-0.020755365,0.01070209,-0.016038835,-0.034788385,0.0022491165,0.024504576,-0.013753651,-0.06334048,0.023840968,-0.030552082,-0.059867628,-0.028440962,0.051033676,-0.072424226,-0.027099717,-0.026008045,-0.0052070655,-0.0464247,0.0017051816,-0.032311402,-0.0021645806,0.018071534,0.099790454,-0.016066017,-0.0015254972,0.048421253,0.008159639,0.04027224,0.021371204,-0.004179582,0.015944473,-0.025673732,-0.017144088,0.05011438,-0.05093968,-0.0047668936,0.03152854,0.12212442,0.013858443,-0.048029285,0.02906345,-0.02767739,-0.014009668,-0.026339386,0.038101435,0.025251571,-0.04063058,0.0053208447,0.05540205,-0.009686166,0.035388105,-0.027749198,0.029841406,-0.011017611,-0.06324806,0.041347377,-0.067260735,0.038438756,2.5356146e-06,0.05679286,0.031306878,-0.03221656,-0.007902821,0.0044169896,0.027820764,-0.022121765,0.030541932,-0.06676786,-0.044670027,0.07649498,-0.0064169774,-0.014955442,0.02590275,0.01817699,-0.01585687,0.05621933,-0.05806764,-0.026786633,-0.074203186,-0.03831249,-0.0035510743,0.025392752,-0.04680923,0.017075263,-0.017471114,-0.013452497,0.012057185,0.01037032,-0.02676133,-0.027146626,-0.0005046433,-0.02090035,0.025481302,0.030159876,-0.0024323459,0.010485037,0.019054793,-0.06419607,-0.019637875,-0.018480698,0.011454,0.10438008,0.045464206,-0.04585003,0.0002896254,0.036723025,-0.026190752,0.03398489,-0.069916725,-0.012952622,0.020946365,0.050555367,0.055723414,0.039747283,0.03301669,-0.051011402,-0.009212728,0.023784135,-0.05163598,0.033987176,-0.022513168,0.04513613,0.011201986,-0.0012647037,0.040139515,0.049641926,-0.014559402,0.008159548,-0.0094711725,0.023629898,-0.044291884,0.05003153,0.021407181,-0.0077326195,0.049313523,0.039467845,0.013804722,0.011884122,0.027833436,0.04363976,-0.028555032,0.040417343,-0.06673432,0.050325535,-0.0004772239,0.0046652076,-0.021307617,0.014929002,0.03916008,-0.0053973,0.016073924,-0.05134517,0.021011215,0.028419992,0.013559534,0.035857342,-0.08797579,-0.002371127,-0.010495601,-0.01175443,0.0059020626,-0.042510316,0.0092646675,0.016153995,-0.0053439443,0.008736286,-0.032228414,0.01913072,0.023287382,-0.030923987,-0.005894318,0.0051393006,-0.053300835,0.0049063945,-0.009768533,-0.013090262,-0.030007875,-0.04617844,0.006044749,-0.03986334,-0.005060334,-0.00714288,-0.003803065,0.017332457,-0.0057087173,0.04548156,-0.052531704,0.054066353,-0.031773727,0.024565708,-0.12776469,0.03263371,0.0428078,-0.022790357,3.5608777e-05,-0.044337086,-0.06886472,0.011648497,-0.04951147,0.04275317,-0.006146347,-0.024183864,0.0040719537,0.032344162,0.04687451,0.0052557257,0.031531923,-0.027585492,0.028160794,0.03355251,-0.0056757177,0.029382735,-0.01145948,-0.04571712,0.0012135992,0.02642167,0.047783803,-0.092233755,0.03042035,0.038338926,-0.043598205,-0.023233347,0.033198886,0.053299244,-0.0036095113,-0.03840501,0.01744095,0.0071736784,-0.06422633,0.034578536,0.04100719,-0.0060131527,-0.027591102,-0.056001894,-0.014049023,-0.040145922,0.006809051,-0.039726485,0.024063127,0.045543965,-0.045904074,0.13166316,0.0020623873,-0.02183652,-0.003383965,0.021479614,-0.026326668,0.013743653,0.03058644,0.018169882,-0.006177666,-0.024560342,0.0025381793,-0.034388337,-0.02161441,0.015755711,-0.054184888,0.023355138,-0.02845183,0.049102433,-0.02259507,0.021070752,-0.05609163,0.032048877,-0.1102388,-0.062316075,0.020840961,-0.0028257275,-0.015641717,0.04156383,-0.04470151,-0.0029633273,-0.002852375,0.052810725,-0.04523065,0.0249364,-0.033440165,0.01286726,-0.020823827,-0.0058489493,0.0076961233,0.04603449,0.009323976,-0.035429433,0.04877631,-0.04161398,0.047075227,0.017343035,0.021242473,0.0063177063,-0.023153596,0.016568078,-0.013307403,0.006743417,0.02556438,0.005847575,-0.0020470605,0.02420215,-0.025770156,-0.01487017,0.041719276,-0.06618045,0.02143708,0.042863287,-0.017654272,0.033947762,0.035907727,-0.0027283363,-0.0044083954,-0.009638667,-0.046771448,-0.04816928,-0.023503557,0.009313014,0.026577447,0.054457024,-0.012735274,0.047440156,0.02483699,-0.20947306,-0.00059385994,-0.008831813,-0.01687958,-0.013595559,0.040861636,0.0025718666,-0.02205911,-0.015601029,0.019270288,0.053535506,-0.04267583,0.016996857,-0.003913816,-0.059300784,0.010097618,-0.026630322,-0.021648394,0.019772185,0.038639564,0.015812505,0.069594406,-0.050346345,-0.0020769625,-0.030615179,-0.011972546,-0.0032032507,0.03321969,0.011467695,0.001648208,0.031647407,-0.010319154,0.028885849,0.026312523,-0.018373448,-0.034865156,-0.016208567,0.0057250094,-0.08110873,0.03978683,0.0064429203,-0.015497373,-0.039013922,6.0507144e-05,0.021530775,0.06323623,0.028824931,0.06053842,-0.027467836,-0.005853541,0.018004296,0.011937428,-0.08728604,0.006940551,0.02013381,0.062290452,0.020167807,0.010667134,0.047876153,-0.025426019,0.052221328,0.060046423,-0.03994933,-0.009787625,-0.013007244,0.022116827,0.056346707,-0.04293475,-0.019238207,0.010693387,0.055489242,-0.049728587,-0.028724939,-0.010601077,0.018893318,-0.038375672,0.009056984,-0.0052347756,-0.075061925,0.0067437803,-0.024233364,-0.014226606,0.0009667354,0.02262229,-0.039600115,-0.02837533,-0.05184802,0.030999951,0.03988972,0.023099044,-0.017475152,-0.05126201,-0.04173462,0.027552104,-0.010142502,-0.0356326,-0.036175683,0.018897412,-0.012844246,-0.02800168,0.024929203,-0.0011810022,-0.050367896,0.027289562,0.017240796,-0.032710537,-0.1190101,0.020251092,-0.010284679,-0.040355124,0.0595853,0.023463663,0.04077302,-0.018702587,0.012178317,0.024399668,-0.0030366543,-0.053953353,-0.04131536,-0.021371875,-0.02162699,-0.026442502,0.01599313,-2.6456813e-05,0.034613207,0.010434845,-0.0334381,0.04756361,0.0208194,0.04011084,0.011324442,-0.069724895,0.03970431,-0.025139904,-0.037896715,0.033499934,0.029567966,-0.012035005,0.048470136,0.014598277,0.057219908,-0.06579989,-0.032541905,0.03683635,0.022974417,0.024448743,0.013097016,-0.020947332,0.005258647,-0.014911157,-0.00012230052,-0.095146045,0.023003614,-0.01538384,-0.018949887,0.016259205,0.03505589,0.030106995,0.013119016,0.032876994,-0.001824455,-0.058982305,-0.008629353,0.025895454,0.0032523794,-0.0022657474,-0.010807122,-0.04746196,0.0035929645,0.04856334,-0.02277638,0.05102127,0.0192693,0.005609396,0.022926908,-0.03451082,0.041105475,0.009155876,-0.036434557,0.022935104]
14	time_entries	Table: time_entries\nDescription: บันทึกเวลาทำงานของ user ในแต่ละ project และ task หัวใจหลักของระบบ time tracking เก็บเวลาเริ่ม-หยุด, ระยะเวลา, billable flag และมูลค่าเงิน\nColumns:\n  id                UUID PRIMARY KEY,                                        -- รหัส time entry\n  team_id           UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,     -- FK → teams\n  project_id        UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,  -- FK → projects: project ที่บันทึกเวลา\n  task_id           UUID REFERENCES project_tasks(id) ON DELETE SET NULL,    -- FK → project_tasks: task ที่บันทึกเวลา (optional ไม่จำเป็นต้องระบุ)\n  user_id           UUID REFERENCES users(id) ON DELETE CASCADE,             -- FK → users: user ที่ log เวลา\n  client_id         UUID REFERENCES clients(id) ON DELETE CASCADE,           -- FK → clients: denormalized จาก project เพื่อ query ง่ายขึ้นโดยไม่ต้อง JOIN projects\n  note              TEXT,                                                     -- คำอธิบายว่าทำอะไรใน session นี้\n  started_at        TIMESTAMPTZ NOT NULL,                                     -- เวลาเริ่มจับเวลา\n  stopped_at        TIMESTAMPTZ,                                              -- เวลาหยุดจับเวลา NULL = timer กำลังรันอยู่\n  duration_seconds  INTEGER,                                                  -- ระยะเวลาทำงานหน่วยวินาที คำนวณจาก stopped_at - started_at (หาร 3600 ได้ชั่วโมง)\n  billable          BOOLEAN NOT NULL DEFAULT TRUE,                            -- true = คิดเงินลูกค้า / false = งาน internal ไม่คิดเงิน\n  hourly_rate_cents INTEGER,                                                  -- ราคาต่อชั่วโมง ณ เวลาที่บันทึก หน่วยสตางค์ (snapshot ไว้ไม่เปลี่ยนย้อนหลัง)\n  amount_cents      INTEGER  	[0.017731037,0.042461853,-0.008896319,0.014648029,0.0061057685,-0.037680577,-0.03273493,-0.026241617,0.02274178,0.02957266,0.030869836,0.01930285,0.11888396,0.04791783,-0.022479951,-0.035388645,-0.004904171,-0.026946578,0.016998943,-0.023034735,0.049903296,-0.05888997,0.012556006,-0.012575791,0.026048182,-0.030596288,0.0060060746,-0.0037737868,-0.04953429,0.021689681,0.033563532,-0.017182114,0.00025767152,0.025754837,0.026016999,0.016498175,-0.009910494,-0.042168014,0.013484807,0.003111206,0.028910527,-0.015150544,0.052110523,-0.029036382,0.009862078,-0.013652502,0.05201386,0.027119804,-0.0070553175,-0.018449515,0.033175252,0.019640833,0.039793607,0.017484771,-0.044331335,0.0017473019,0.027796473,0.027715974,-0.03190023,-0.0022914105,-0.0013356277,0.05864117,-0.005151567,0.017771203,0.012025748,-0.0077762185,0.018415948,-0.027129443,-0.058461234,-0.031856395,-0.021068828,0.019976752,0.09608177,-0.013760621,-0.006608843,-0.002366848,-0.036351345,0.001907377,0.028740374,-0.0029872977,0.060819257,0.017795365,0.0052456628,0.021807954,0.0036053846,0.0022405048,-0.017944807,0.039880272,0.042991977,0.037920754,0.032689303,-0.016802866,-0.048234507,0.023125648,0.03309991,0.019917237,-0.005341228,0.0054837423,0.04282357,-0.03323784,-0.0124105755,-0.07453717,-0.0023184326,-0.027759146,-0.08619875,-0.025823273,-0.023190374,-0.05768451,0.058441486,-0.021212962,-0.017539702,0.0001925814,0.014379537,-0.06141072,0.03418086,-0.057790026,0.06156836,-0.059778433,0.0148949595,-0.06420345,-0.061600532,-0.004547712,0.00529882,-0.019530464,0.044132285,-0.03560164,-0.007252694,-0.017836293,0.007967313,-0.059377443,-0.029931262,-0.03349876,0.002789832,-0.0050162114,-0.02217178,0.053672835,0.026319075,-0.0044353628,-0.005597269,0.018041959,0.031476505,-0.035147674,0.018954735,0.055245556,0.013256944,-0.07562128,-0.0146172615,0.011150758,-0.015996067,0.036571227,0.039026324,-0.05190493,-0.03418113,0.006515338,0.045248862,-0.010419033,-0.053257413,-0.020035544,0.01913632,0.032564733,0.013606107,0.0007772539,0.0071618296,-0.03679176,0.029802818,0.007486784,-0.04728519,0.021871971,-0.045912366,0.008703536,-0.0021162457,-0.06746972,-0.08161206,0.022532603,-0.025633376,-0.034829184,-0.01557735,-0.029944789,-0.039589554,-0.05206674,-0.06958832,0.0057047033,-0.05603906,0.021828143,-0.013427079,-0.017862184,-0.030108985,-0.0122652445,0.035089143,0.013943324,0.0010699091,0.08212624,0.008161726,0.04371399,0.026498212,0.0072688167,0.03267658,0.013064213,0.0027467557,-0.040245954,0.006051866,0.0015425506,0.034315914,0.041625775,0.015360338,-0.066353396,-0.004532357,0.035098568,0.035986386,0.010704642,-0.0366899,0.03710449,-0.05089261,0.047448393,-0.028156882,-0.060975596,0.04067377,0.022635002,-0.015716374,0.03521523,0.0021530564,-0.060293093,0.053751204,0.04805877,-0.023673922,0.0075554783,0.02581509,-0.010580791,0.030903537,0.02839754,0.047961537,0.10115531,-0.046774752,0.009153342,-0.022510055,-0.024465509,0.04649145,-0.011615902,-0.017811455,-0.12026288,-0.051135942,0.027218515,0.011730348,-0.012564371,0.05364274,0.00097275956,-0.048090305,0.038511544,-0.04440389,0.022293625,0.031296622,-0.04953999,0.005953506,-0.016556501,0.022827368,-0.00040396058,-0.05173029,0.010787269,0.050070554,0.0071772146,0.00731724,-0.0072000045,0.003989431,-0.0338124,0.020815201,-0.027234675,0.00031554114,-0.030404659,-0.05099854,-0.0062672477,-0.008920369,-0.02835821,-0.039610125,-0.01991052,0.012197921,-0.0035401327,-0.07276061,0.020973815,-0.019021641,-0.052154377,-0.015214253,0.04383431,-0.0783393,-0.030465886,-0.021714734,-0.002188316,-0.046517946,0.014172259,-0.03993325,-0.01806537,0.022796556,0.08083369,-0.011801068,0.0066374084,0.057163432,0.007534085,0.03788834,0.012298467,-0.003180339,-0.021512195,-0.020303074,-0.0115652075,0.01760246,-0.06400234,-0.046546314,0.029254364,0.117475815,0.022432303,-0.0701655,0.035940465,-0.01758441,-0.01303021,-0.011686533,0.052624285,0.036956098,-0.046225213,-0.0043250667,0.057585124,-0.0044503594,0.02833401,-0.03624232,0.033284456,-0.021484194,-0.089616664,0.039363813,-0.044630677,0.031873077,-0.008964491,0.03808253,0.0339505,-0.0047416724,0.010379731,0.023546254,0.039251592,-0.04119863,0.027608296,-0.055680353,-0.061255626,0.05432788,-0.0010920501,-0.027923526,0.033397198,0.029936235,0.0035990141,0.05349383,-0.071223654,-0.03026776,-0.071674265,-0.04216069,0.0076665417,0.0126984725,-0.047527462,0.02496872,-0.023469234,-0.027468976,0.02638283,0.012257799,-0.009592824,0.0008013169,-0.014420219,0.006359989,0.021762775,0.025275648,-0.013375472,0.008973571,0.02714168,-0.0736526,-0.025988149,0.01213075,0.021408819,0.107549444,0.052327964,-0.033124227,-0.00042895667,0.04218495,-0.028811794,0.049433555,-0.07168779,-0.010797985,0.034295164,0.044686258,0.04759948,0.028010257,0.040667884,-0.036663912,-0.011284623,0.014332214,-0.043594226,0.036144536,-0.009242758,0.050640296,0.009379055,-0.013467547,0.04406712,0.059365395,-0.03810949,-0.0058047725,-0.0046165343,0.0132438345,-0.04854556,0.049918123,0.013241023,-0.026197445,0.056617234,0.04124373,0.02330471,-0.023964541,0.051602755,0.024459165,-0.03656685,0.047985192,-0.05064579,0.054791868,0.006693995,0.030309819,0.0090346355,0.01685394,0.039726853,0.00046346444,0.01262568,-0.061483953,0.022517271,0.024484674,-0.002440121,0.03381117,-0.085767046,0.010970755,-0.017805707,-0.023964662,0.011463882,-0.034917127,0.017263927,0.019971862,0.017421888,0.039850127,-0.0396486,0.022181692,0.024966776,-0.020917257,0.014623821,-0.022334473,-0.043107014,0.016801361,-0.0056149326,-0.02660924,0.0077947453,-0.03717683,0.00825848,-0.031896293,-0.029011603,-0.0054084947,0.0062824897,0.012301739,-0.013310509,0.035052083,-0.05682866,0.038657557,0.0072061294,0.0023472179,-0.10700109,0.014910161,0.034861553,0.0046920367,0.009623308,-0.04364194,-0.070274845,0.026504599,-0.07079081,0.032517552,0.013574116,-0.038879577,-0.01901599,-0.014857292,0.036701877,0.008832335,0.033187985,0.012058646,0.04522212,0.032535903,0.0030294238,0.058203,-0.01042277,-0.034622632,0.0044043027,0.008301281,0.060063187,-0.09887541,0.024635991,0.035986632,-0.04088274,-0.026318137,0.05551679,0.031829406,-0.02280248,-0.0024449164,0.041711766,0.0014430289,-0.053634673,0.06311588,0.03777526,-0.023755675,-0.023765195,-0.035766155,0.008195736,-0.029029457,-0.002954663,-0.033851992,0.028084137,0.049984563,-0.034799658,0.12715526,0.0022013024,-0.013707134,-0.013208343,0.016717963,0.007414473,-0.02800823,0.02519174,0.0071738083,-0.035320956,-0.028565133,0.032993365,-0.024231223,-0.035258126,0.01319454,-0.05348405,0.009703235,-0.01830634,0.037203696,-0.028130943,0.028596569,-0.020264762,0.03360635,-0.106222644,-0.054848675,0.018819194,-0.014625212,-0.007297674,0.034378115,-0.037865836,0.02136214,-0.015286976,0.021740308,-0.040789448,0.0130723845,-0.051628217,0.025059724,-0.012155245,-0.01909115,-0.0089715645,0.05989498,-0.0072588543,-0.026282743,0.046516214,-0.009293198,0.05843874,0.023843251,0.02932464,0.025475241,-0.02044429,0.009073292,-0.025154386,0.0053256103,0.0026923548,0.017530689,-0.0035606045,0.035830583,-0.019780867,-0.013929586,0.053181157,-0.054392047,0.038314864,0.044932976,0.01184618,0.02176412,0.023423837,-0.010816418,-0.013529263,-0.0019354759,-0.0560011,-0.055085026,-0.0055867005,0.016541893,0.015537797,0.04535034,0.0052841837,0.037248567,0.01352186,-0.1979317,0.006160025,0.006850977,-0.040751204,-0.004369949,0.04064545,0.039656296,-0.02493467,0.0045596063,0.028883783,0.04503849,-0.016302703,0.02162701,-0.023139345,-0.026172113,0.007984662,-0.0051702056,-0.016776158,0.019596089,0.02381102,0.009267664,0.06699985,-0.03642522,-0.010303072,-0.044017404,-0.03330822,0.02444236,0.026801122,0.026264466,0.0049245525,0.03886901,-0.007290205,0.029643172,0.023572203,-0.02568261,-0.027949637,-0.018282544,-0.00036979967,-0.10496155,0.03530106,0.03702507,-0.009763167,-0.04619557,0.010832198,0.007399566,0.0392493,0.030743161,0.035264365,-0.022813449,-0.0067628277,0.02041223,0.007929518,-0.09829826,0.020780267,0.0011111198,0.061214667,0.02820267,0.0026310598,0.02514305,-0.030824646,0.06052254,0.036380358,-0.013698591,-0.007378641,-0.005350614,0.015731143,0.050001618,-0.019940356,-0.01597177,0.014699678,0.045971744,-0.04186883,-0.0047027473,-0.009974835,0.025100531,-0.0440284,0.019647961,-0.012330331,-0.07797492,0.0045074187,-0.02557935,-0.037429925,-0.016501067,0.04058384,-0.03634184,-0.047024496,-0.06457501,0.018312821,0.038611185,0.014876067,-0.015845167,-0.040225063,-0.019673709,-0.02911456,0.01653073,-0.02590809,-0.045939676,0.020184226,-0.021031508,-0.018876858,0.018576542,0.0072520357,-0.01828103,0.02840076,0.051294997,-0.039506927,-0.10757072,0.029141247,-0.044928502,-0.030013837,0.04657773,0.02817939,0.04332078,-0.008916536,0.008525455,0.00044102955,0.0104547655,-0.03094644,-0.034359924,-0.032122705,-0.01317664,-0.024692293,-0.018925862,0.0038864156,0.020266714,-0.0022598896,-0.04065806,0.04965369,0.0013075111,0.025163257,0.007149542,-0.06185514,0.03283686,-0.010969592,-0.021082215,0.042784274,0.011626821,-0.005682827,0.028414909,0.012293192,0.086420976,-0.060073048,-0.041298945,0.0507853,-0.0041593425,0.015386972,-0.012166669,-0.009116234,0.013596184,-0.021512078,-0.018152403,-0.093007155,0.006366144,-0.0118351225,-0.02218565,0.03012331,0.021900883,0.025902683,0.014966071,0.039506353,-0.017234426,-0.051689,-0.018674033,0.014298033,-0.0142566655,-0.007681788,-0.012585115,-0.04529435,0.02754477,0.0069072735,-0.021106498,0.034553498,0.01726032,0.021510553,0.01870304,-0.01975734,0.05457044,0.004797819,0.0008513612,0.038669225]
15	users	Table: users\nDescription: ผู้ใช้งานในระบบ login ด้วย email และ password user คนหนึ่งสามารถเป็นสมาชิกได้หลาย team และมี role ต่างกันในแต่ละ team\nColumns:\n  id                  UUID PRIMARY KEY,         -- รหัส user สร้างอัตโนมัติ\n  email               VARCHAR(255) NOT NULL UNIQUE, -- อีเมลสำหรับ login ต้อง unique ทั้งระบบ\n  name                VARCHAR(255) NOT NULL,    -- ชื่อจริงของผู้ใช้\n  password_hash       VARCHAR(255) NOT NULL,    -- bcrypt hash ของรหัสผ่าน ไม่เก็บรหัสผ่านตรงๆ\n  instance_role       TEXT NOT NULL DEFAULT 'USER', -- สิทธิ์ระดับระบบ: USER (ทั่วไป) หรือ ADMIN (จัดการทุก team ได้)\n  display_name        VARCHAR(120),             -- ชื่อที่แสดงใน UI แทนชื่อจริง เช่น ชื่อเล่น\n  email_verified_at   TIMESTAMPTZ,              -- เวลาที่ยืนยัน email ถ้า NULL = ยังไม่ยืนยัน\n  created_at          TIMESTAMPTZ NOT NULL,     -- วันที่สมัครสมาชิก\n  updated_at          TIMESTAMPTZ NOT NULL      -- วันที่แก้ไขข้อมูลล่าสุด	[0.015544718,0.029251179,-0.026337776,0.0016544807,0.0042520915,-0.06382355,-0.05256142,-0.03530478,0.05258324,0.023797406,0.013439419,0.009334943,0.1277635,0.03756525,-0.0110819405,-0.011990799,-0.009580555,-0.020683857,-0.012568286,-0.009722725,0.049243134,-0.043865,0.022803985,-0.0047122864,0.022498045,-0.02768477,0.0008562876,-0.013917177,-0.019602336,0.008945,0.032548964,-0.01719102,-0.026624672,0.04612895,0.02425698,0.00964651,-0.0056001525,-0.013350954,0.00038042935,0.00047031982,0.025729258,5.125201e-05,0.02927754,-0.039137494,0.024601849,-0.022098633,0.05050193,0.017313179,-0.03318992,-0.023835264,0.025637522,0.023964928,0.029060917,0.0018927207,-0.02240791,-0.021357762,0.024801403,0.030605774,-0.037320945,0.03402075,-0.008999466,0.0383449,-0.0011568142,0.020571,0.013696335,-0.009284419,0.014578741,-0.017898766,-0.032772735,-0.03138783,-0.014157318,-0.006734734,0.10521307,-0.0098141115,-0.024554182,-0.0036963567,-0.06958914,0.01612311,0.018693246,0.000854096,0.042855892,0.019004552,0.031437706,0.007321371,-0.016499901,-0.014100006,-0.011137795,0.05850625,0.04503927,0.05247888,0.0058007413,-0.043722723,-0.039785147,0.007745192,0.033836104,0.03714267,-0.014363484,0.007844566,0.058231052,-0.040901255,-0.012696561,-0.09683524,-0.039721116,-0.033846416,-0.06691132,-0.041276533,-0.0035631307,-0.047685076,0.042992726,-0.038766894,0.005665405,0.004172196,0.005504253,-0.04707004,0.042313367,-0.032543186,0.062327623,-0.056990318,0.016086541,-0.0479962,-0.050994452,0.014791955,-0.021053962,-0.0051936433,0.054068305,-0.022571169,-0.012519773,-0.0048461794,0.026890622,-0.05609699,-0.03511051,-0.050978992,0.008108464,0.02052831,-0.026677527,0.05182122,0.03912626,-0.014080018,-0.007014131,0.0058426694,0.038736407,-0.023224877,0.030576222,0.056532398,0.0058258367,-0.07777168,-0.00362016,0.016149553,-0.0117463125,0.010307561,0.037948996,-0.06405519,-0.04185503,-0.003289797,0.043768913,0.011084685,-0.018444918,0.0023506235,0.024189187,0.055336937,0.027234532,-0.013382729,0.0008180136,-0.039526943,0.034375146,0.0022672468,-0.014346323,0.012718147,-0.036873244,-0.010379093,-0.016822247,-0.04596222,-0.09925445,0.030856792,-0.021606278,-0.016302608,-0.029549003,-0.044445604,-0.020472357,-0.06160948,-0.083155744,0.0004954528,-0.035707455,0.026973817,-0.01836949,-0.019125998,-0.005673555,-0.0238477,0.037641477,-0.000620137,-0.017864784,0.06898332,0.0003847898,0.03136094,0.03611037,-0.011052682,0.03606628,0.025795521,-0.0071021584,-0.058514003,0.009245322,0.0033194537,0.05475986,0.045434333,0.034974303,-0.071866944,-0.02048592,0.032583687,0.011611887,0.015943265,-0.0065968772,0.04667984,-0.00939947,0.04799696,-0.028640252,-0.0412239,0.017953036,0.0049651526,0.0012966598,0.037506353,0.010327852,-0.04439474,0.058384053,0.035949048,-0.014162897,0.013410342,0.015675157,-0.012726645,0.03184692,0.058681756,0.052981704,0.08274283,-0.008751929,0.04348059,-0.025668917,-0.020557132,0.01964935,-0.005362902,-0.006807416,-0.09781622,-0.023144936,0.030091427,0.023211423,-0.022358665,0.020320736,-0.022654617,-0.06225312,0.046094965,-0.026197374,0.01963191,0.042989496,-0.044150595,0.0046003317,-0.03289785,0.016454358,0.023306595,-0.023290968,-0.0028539805,0.03958911,0.004572582,0.0051497933,0.0036277736,0.010128037,-0.0365362,0.016314128,0.012769282,0.009564169,-0.01438296,-0.06957343,0.0068143834,0.009629583,-0.011306179,-0.044958025,0.008877231,0.02733943,-0.009324925,-0.068194136,0.034854196,-0.01484214,-0.057411503,-0.039973095,0.04772659,-0.054930735,-0.03537078,-0.042255376,0.0033522504,-0.0419148,-0.0024838704,-0.055971712,0.018890798,0.01703869,0.07322535,-0.014430334,0.0124265645,0.06396145,0.016201524,0.03173875,0.006655717,-0.0210994,-0.0049278806,-0.02213438,-0.0033578328,0.03155785,-0.057143282,-0.008674977,0.021416713,0.12741458,0.0054520904,-0.055584628,0.057164416,-0.029864868,-0.0003290635,-0.0102459565,0.05144429,0.04808517,-0.03464992,0.021121139,0.055645265,-0.0073160403,0.05068049,-0.03135979,0.013309898,-0.0100643225,-0.056287624,0.048564248,-0.050082464,0.03734403,-0.003642041,0.062766984,0.03270835,-0.014550105,0.0019992788,0.0026837932,0.039572287,-0.052114308,0.0212075,-0.053089026,-0.030798113,0.09208608,-0.006882144,-0.02258544,0.02960136,0.035374757,-0.010296351,0.059610613,-0.06745008,-0.026040312,-0.059575655,-0.029920992,-0.0046362304,0.05252655,-0.047022067,0.023997033,-0.018113459,-0.017812539,0.013795304,0.010416907,-0.021564357,-0.03871425,0.00881851,-0.03089189,0.025539674,0.027438264,-0.0004006044,0.025896888,0.010059026,-0.0771061,-0.027701624,-0.008655749,-0.008760269,0.074959405,0.051208545,-0.048045337,-0.025234416,0.02206874,-0.01873834,0.007574286,-0.068419956,-0.014032799,0.021061463,0.039190706,0.058237292,0.045120522,0.027112113,-0.05408771,0.014808416,0.013674815,-0.07802904,0.033927213,-0.0107207205,0.052563623,0.0030913316,-0.027552899,0.043132566,0.047656335,-0.0069637643,0.011369428,-0.004633854,0.02535028,-0.04264921,0.054608095,0.016704507,0.0093047265,0.054012965,0.045136686,-0.003186843,-0.006156222,0.030197164,0.0497462,-0.026950778,0.041737475,-0.045590702,0.0358041,0.0038651673,0.007401109,-0.019172788,-0.011969381,0.03543463,-0.0038963798,0.020635774,-0.043012213,0.02251905,0.026562907,0.011033034,0.02104406,-0.0928923,0.010784731,0.011227336,-0.011260417,-0.005336038,-0.046491344,-0.00023755625,0.013073487,-0.0054176026,-0.0022181044,-0.023043111,0.012377157,0.030035937,-0.029029634,0.015973527,-0.00651933,-0.02706298,0.0027879837,-0.0060372367,-0.018716587,-0.010983338,-0.029990349,-0.0018009573,-0.03536207,0.0080468925,-0.00023808918,-0.0141308755,0.0081781205,0.0020489977,0.05137672,-0.044327717,0.037446808,-0.027131986,0.025280312,-0.11630496,0.024250977,0.053369936,0.0006437529,0.005816983,-0.054993857,-0.06633645,0.014873759,-0.059504762,0.023769757,0.0047236886,-0.02362632,-0.018466176,0.024578037,0.040615298,0.00031217057,0.036302786,-0.024449443,0.023860471,0.0286016,-0.017577615,0.014149357,-0.012015086,-0.043007202,0.009634352,-0.00813618,0.024234101,-0.0866498,0.037382666,0.0532308,-0.030921226,-0.026886437,0.030386485,0.05491855,0.004103021,-0.0031253383,0.04893402,0.017194193,-0.0732893,0.03689472,0.024493081,-0.005719132,-0.030898517,-0.034976397,-0.01247269,-0.042577494,0.018709823,-0.021168826,0.036391053,0.035476826,-0.040163733,0.12611309,-0.014480056,-0.02588782,-0.008450558,0.039741833,-0.020139607,-0.008120656,0.02575726,0.025058703,-0.030348882,-0.02033101,0.0075051757,-0.040525656,-0.006006012,0.018332463,-0.05312067,0.0040921294,-0.02140222,0.04813582,-0.01492869,0.017882027,-0.05423997,0.021519177,-0.10823805,-0.033328496,0.03147491,-0.0042282105,-0.025699323,0.043214083,-0.038150016,-0.0037467622,-0.020170564,0.017652864,-0.05350016,0.027944338,-0.02760261,0.014856864,-0.020991655,-0.009711509,-0.0063454974,0.041525338,0.001385678,-0.047893044,0.06520694,-0.04076153,0.051419143,0.010508108,0.024907123,-0.004579757,-0.020739818,0.014094488,-0.032347497,-0.0036622433,0.0089566745,-0.015255202,0.018678203,0.023773132,-0.02477312,-0.024322195,0.050205536,-0.074229226,0.020361224,0.045941915,-0.016513912,0.044291273,0.044068284,-0.010457711,-0.026512222,0.0032497135,-0.065514155,-0.05298607,-0.016713977,0.0044011385,0.007206188,0.040394176,-0.0072284536,0.057566065,0.0038127382,-0.21475677,-0.014636959,-0.0020587505,-0.045768913,-0.007530583,0.041987572,0.026973372,-0.020011412,-0.014191105,0.01687447,0.05260023,-0.03177689,0.025757726,0.008568262,-0.071926445,-0.004930322,-0.023234958,-0.006877782,0.01594327,-0.016043669,0.011291052,0.057183105,-0.04852378,0.0020055212,-0.021263357,0.004746352,-0.022136288,0.0300753,0.007977794,0.0163477,0.05663271,0.011283873,0.022942197,0.024599265,-0.0227406,-0.027231546,-0.011977032,0.017572071,-0.07645328,0.037271902,0.006347036,-0.008691129,-0.039832093,0.007308153,-0.001350161,0.04887332,0.025183378,0.037072454,-0.026297167,-0.009356481,0.0017137416,0.014585445,-0.097513095,0.007779055,0.009365777,0.037127513,0.02284843,0.01919058,0.0499871,-0.022265334,0.054226093,0.0663932,-0.037177347,0.004105323,-0.022303801,0.029694676,0.077460006,-0.044497408,-0.016859235,0.04025759,0.05431162,-0.043563113,-0.015973136,-0.004514251,0.025193421,-0.03515744,0.007983342,-0.013259943,-0.048638042,0.03036342,-0.032589734,-0.026233774,-0.002895149,0.016748512,-0.03199902,-0.03795304,-0.053653233,0.0133596705,0.030813655,0.034568585,-0.008709464,-0.052327443,-0.021559827,0.028950524,0.0016260226,-0.009882921,-0.033014882,0.0072721257,-0.019677851,-0.032937236,0.009232962,-0.008587174,-0.05253139,0.006588887,0.04690829,-0.032296356,-0.11940246,0.044057194,-0.02291019,-0.06288495,0.046871305,0.02186679,0.036399957,-0.019112274,0.010024614,0.017524477,0.033167306,-0.049698874,-0.051650845,-0.04761553,-0.01444923,-0.017060544,0.011197429,-0.0009314105,0.039335746,0.024426565,-0.01404552,0.03862008,0.010052713,0.049002092,0.0009012551,-0.06730678,0.04685868,-0.0059208996,-0.009800188,0.04122547,0.028779887,0.0020081117,0.03271435,0.016057303,0.0943968,-0.081085645,-0.032568082,0.026826432,0.01930989,0.044595294,0.0073910872,-0.0048004156,0.015090791,-0.010180584,0.009867036,-0.07440294,0.020065928,-0.019389454,-0.026568113,0.01482838,0.02928997,0.014859843,0.0114682475,0.030742666,0.009883649,-0.053189527,-0.020441351,0.010193126,0.008653508,0.008601142,0.0013902643,-0.020384721,0.02848371,0.03561304,-0.034164242,0.028288597,0.012288126,-0.0074336315,0.02125645,-0.031020835,0.055371765,-0.00056858675,-0.027604898,0.02577185]
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sessions (id, user_id, expires_at, created_at) FROM stdin;
\.


--
-- Data for Name: task_assignees; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.task_assignees (id, team_id, task_id, user_id, created_at) FROM stdin;
b2000000-0000-0000-0000-000000000001	a1000000-0000-0000-0000-000000000001	a2000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000006	2026-04-20 19:01:28.11178+00
b2000000-0000-0000-0000-000000000002	a1000000-0000-0000-0000-000000000001	a2000000-0000-0000-0000-000000000002	b1000000-0000-0000-0000-000000000002	2026-04-20 19:01:28.11178+00
b2000000-0000-0000-0000-000000000003	a1000000-0000-0000-0000-000000000001	a2000000-0000-0000-0000-000000000003	b1000000-0000-0000-0000-000000000002	2026-04-20 19:01:28.11178+00
b2000000-0000-0000-0000-000000000004	a1000000-0000-0000-0000-000000000001	a2000000-0000-0000-0000-000000000005	b1000000-0000-0000-0000-000000000003	2026-04-20 19:01:28.11178+00
b2000000-0000-0000-0000-000000000005	a1000000-0000-0000-0000-000000000001	a2000000-0000-0000-0000-000000000006	b1000000-0000-0000-0000-000000000003	2026-04-20 19:01:28.11178+00
b2000000-0000-0000-0000-000000000006	a1000000-0000-0000-0000-000000000001	a2000000-0000-0000-0000-000000000008	b1000000-0000-0000-0000-000000000002	2026-04-20 19:01:28.11178+00
b2000000-0000-0000-0000-000000000007	a1000000-0000-0000-0000-000000000001	a2000000-0000-0000-0000-000000000009	b1000000-0000-0000-0000-000000000006	2026-04-20 19:01:28.11178+00
b2000000-0000-0000-0000-000000000008	a1000000-0000-0000-0000-000000000002	a2000000-0000-0000-0000-000000000010	b1000000-0000-0000-0000-000000000004	2026-04-20 19:01:28.11178+00
b2000000-0000-0000-0000-000000000009	a1000000-0000-0000-0000-000000000002	a2000000-0000-0000-0000-000000000011	b1000000-0000-0000-0000-000000000005	2026-04-20 19:01:28.11178+00
b2000000-0000-0000-0000-000000000010	a1000000-0000-0000-0000-000000000002	a2000000-0000-0000-0000-000000000013	b1000000-0000-0000-0000-000000000004	2026-04-20 19:01:28.11178+00
\.


--
-- Data for Name: team_memberships; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.team_memberships (id, team_id, user_id, role, invited_at, joined_at, created_at) FROM stdin;
40ab028a-f89a-4b4d-8c70-6ddc39f423f1	6eb9a25a-ec68-464b-a265-0eba6a0f8baa	72521442-e104-4783-a7d0-0157a489ca1e	OWNER	\N	2026-04-20 18:48:27.90862+00	2026-04-20 18:48:27.90862+00
c1000000-0000-0000-0000-000000000001	a1000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000001	OWNER	\N	2026-01-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
c1000000-0000-0000-0000-000000000002	a1000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	ADMIN	\N	2026-01-25 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
c1000000-0000-0000-0000-000000000003	a1000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000003	MEMBER	\N	2026-01-30 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
c1000000-0000-0000-0000-000000000004	a1000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000006	MEMBER	\N	2026-03-21 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
c1000000-0000-0000-0000-000000000005	a1000000-0000-0000-0000-000000000002	b1000000-0000-0000-0000-000000000004	OWNER	\N	2026-02-09 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
c1000000-0000-0000-0000-000000000006	a1000000-0000-0000-0000-000000000002	b1000000-0000-0000-0000-000000000005	MEMBER	\N	2026-02-19 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
c1000000-0000-0000-0000-000000000007	a1000000-0000-0000-0000-000000000002	b1000000-0000-0000-0000-000000000001	VIEWER	\N	2026-03-06 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
6a2f5236-6643-4238-966b-4b8c0c4a5bba	26705c95-f666-4ce8-9116-14387d0705fc	72521442-e104-4783-a7d0-0157a489ca1e	ADMIN	2026-04-21 05:52:09.675087+00	2026-04-21 05:52:09.675087+00	2026-04-21 05:52:09.675087+00
365fb79d-6d67-4012-b19f-f8216b94dd2b	2309fb3c-509d-4ff2-aaff-5a82c32b0e9c	8e606d22-8589-4965-be20-e7c5ba934208	OWNER	\N	2026-04-21 13:51:02.05452+00	2026-04-21 13:51:02.05452+00
\.


--
-- Data for Name: teams; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.teams (id, name, slug, billing_address, created_at, updated_at) FROM stdin;
6eb9a25a-ec68-464b-a265-0eba6a0f8baa	Worada Sarakhon	worada-sarakhon-1776710907906	\N	2026-04-20 18:48:27.907076+00	2026-04-20 18:48:27.907076+00
a1000000-0000-0000-0000-000000000001	PixelCraft Studio	pixelcraft-studio	{"city": "Bangkok", "street": "123 Sukhumvit Rd", "country": "TH", "postal_code": "10110"}	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
a1000000-0000-0000-0000-000000000002	DevOps Squad	devops-squad	{"city": "Bangkok", "street": "456 Silom Rd", "country": "TH", "postal_code": "10500"}	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
26705c95-f666-4ce8-9116-14387d0705fc	gugugaga	1418-00	\N	2026-04-21 04:13:31.363201+00	2026-04-21 04:13:31.363201+00
2309fb3c-509d-4ff2-aaff-5a82c32b0e9c	sarakhon	sarakhon-1776779462053	\N	2026-04-21 13:51:02.05357+00	2026-04-21 13:51:02.05357+00
\.


--
-- Data for Name: time_entries; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.time_entries (id, team_id, project_id, task_id, user_id, client_id, note, started_at, stopped_at, duration_seconds, billable, hourly_rate_cents, amount_cents, created_at, updated_at) FROM stdin;
c2000000-0000-0000-0000-000000000001	a1000000-0000-0000-0000-000000000001	e1000000-0000-0000-0000-000000000001	a2000000-0000-0000-0000-000000000001	b1000000-0000-0000-0000-000000000002	d1000000-0000-0000-0000-000000000001	Reviewed Figma wireframes with client	2026-02-19 19:01:28.11178+00	2026-02-19 22:01:28.11178+00	10800	t	15000	45000	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
c2000000-0000-0000-0000-000000000002	a1000000-0000-0000-0000-000000000001	e1000000-0000-0000-0000-000000000001	a2000000-0000-0000-0000-000000000002	b1000000-0000-0000-0000-000000000006	d1000000-0000-0000-0000-000000000001	Setup Next.js project structure	2026-02-24 19:01:28.11178+00	2026-02-25 01:01:28.11178+00	21600	t	15000	90000	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
c2000000-0000-0000-0000-000000000003	a1000000-0000-0000-0000-000000000001	e1000000-0000-0000-0000-000000000001	a2000000-0000-0000-0000-000000000002	b1000000-0000-0000-0000-000000000006	d1000000-0000-0000-0000-000000000001	Implemented product listing page	2026-03-01 19:01:28.11178+00	2026-03-02 03:01:28.11178+00	28800	t	15000	120000	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
c2000000-0000-0000-0000-000000000004	a1000000-0000-0000-0000-000000000001	e1000000-0000-0000-0000-000000000001	a2000000-0000-0000-0000-000000000002	b1000000-0000-0000-0000-000000000002	d1000000-0000-0000-0000-000000000001	Shopping cart and checkout flow	2026-03-06 19:01:28.11178+00	2026-03-07 02:01:28.11178+00	25200	t	15000	105000	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
c2000000-0000-0000-0000-000000000005	a1000000-0000-0000-0000-000000000001	e1000000-0000-0000-0000-000000000001	a2000000-0000-0000-0000-000000000003	b1000000-0000-0000-0000-000000000002	d1000000-0000-0000-0000-000000000001	Stripe payment gateway integration	2026-03-11 19:01:28.11178+00	2026-03-12 00:01:28.11178+00	18000	t	15000	75000	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
c2000000-0000-0000-0000-000000000006	a1000000-0000-0000-0000-000000000001	e1000000-0000-0000-0000-000000000001	a2000000-0000-0000-0000-000000000004	b1000000-0000-0000-0000-000000000001	d1000000-0000-0000-0000-000000000001	Weekly sprint planning	2026-03-16 19:01:28.11178+00	2026-03-16 21:01:28.11178+00	7200	f	\N	\N	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
c2000000-0000-0000-0000-000000000007	a1000000-0000-0000-0000-000000000001	e1000000-0000-0000-0000-000000000002	a2000000-0000-0000-0000-000000000005	b1000000-0000-0000-0000-000000000003	d1000000-0000-0000-0000-000000000001	Setup React Navigation structure	2026-03-21 19:01:28.11178+00	2026-03-21 23:01:28.11178+00	14400	t	15000	60000	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
c2000000-0000-0000-0000-000000000008	a1000000-0000-0000-0000-000000000001	e1000000-0000-0000-0000-000000000002	a2000000-0000-0000-0000-000000000006	b1000000-0000-0000-0000-000000000003	d1000000-0000-0000-0000-000000000001	JWT authentication implementation	2026-03-26 19:01:28.11178+00	2026-03-27 01:01:28.11178+00	21600	t	15000	90000	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
c2000000-0000-0000-0000-000000000009	a1000000-0000-0000-0000-000000000001	e1000000-0000-0000-0000-000000000002	a2000000-0000-0000-0000-000000000007	b1000000-0000-0000-0000-000000000003	d1000000-0000-0000-0000-000000000001	Firebase push notification setup	2026-03-31 19:01:28.11178+00	2026-04-01 00:01:28.11178+00	18000	t	15000	75000	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
c2000000-0000-0000-0000-000000000010	a1000000-0000-0000-0000-000000000001	e1000000-0000-0000-0000-000000000003	\N	b1000000-0000-0000-0000-000000000002	d1000000-0000-0000-0000-000000000002	Salesforce API mapping and schema design	2025-12-21 19:01:28.11178+00	2025-12-22 03:01:28.11178+00	28800	t	20000	160000	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
c2000000-0000-0000-0000-000000000011	a1000000-0000-0000-0000-000000000001	e1000000-0000-0000-0000-000000000003	\N	b1000000-0000-0000-0000-000000000003	d1000000-0000-0000-0000-000000000002	ERP connector development	2026-01-10 19:01:28.11178+00	2026-01-11 05:01:28.11178+00	36000	t	20000	200000	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
c2000000-0000-0000-0000-000000000012	a1000000-0000-0000-0000-000000000001	e1000000-0000-0000-0000-000000000003	\N	b1000000-0000-0000-0000-000000000002	d1000000-0000-0000-0000-000000000002	Integration testing and UAT support	2026-01-30 19:01:28.11178+00	2026-01-31 01:01:28.11178+00	21600	t	20000	120000	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
c2000000-0000-0000-0000-000000000013	a1000000-0000-0000-0000-000000000001	e1000000-0000-0000-0000-000000000004	a2000000-0000-0000-0000-000000000008	b1000000-0000-0000-0000-000000000002	d1000000-0000-0000-0000-000000000002	PostgreSQL query optimization for dashboard	2026-04-05 19:01:28.11178+00	2026-04-06 02:01:28.11178+00	25200	t	20000	140000	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
c2000000-0000-0000-0000-000000000014	a1000000-0000-0000-0000-000000000001	e1000000-0000-0000-0000-000000000004	a2000000-0000-0000-0000-000000000009	b1000000-0000-0000-0000-000000000006	d1000000-0000-0000-0000-000000000002	Line chart and bar chart components	2026-04-10 19:01:28.11178+00	2026-04-11 03:01:28.11178+00	28800	t	20000	160000	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
c2000000-0000-0000-0000-000000000015	a1000000-0000-0000-0000-000000000002	e1000000-0000-0000-0000-000000000006	a2000000-0000-0000-0000-000000000010	b1000000-0000-0000-0000-000000000004	d1000000-0000-0000-0000-000000000004	CoreDNS configuration and service mesh	2026-03-01 19:01:28.11178+00	2026-03-02 03:01:28.11178+00	28800	t	25000	200000	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
c2000000-0000-0000-0000-000000000016	a1000000-0000-0000-0000-000000000002	e1000000-0000-0000-0000-000000000006	a2000000-0000-0000-0000-000000000011	b1000000-0000-0000-0000-000000000005	d1000000-0000-0000-0000-000000000004	Helm charts for backend services	2026-03-11 19:01:28.11178+00	2026-03-12 05:01:28.11178+00	36000	t	25000	250000	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
c2000000-0000-0000-0000-000000000017	a1000000-0000-0000-0000-000000000002	e1000000-0000-0000-0000-000000000006	a2000000-0000-0000-0000-000000000012	b1000000-0000-0000-0000-000000000004	d1000000-0000-0000-0000-000000000004	Prometheus metrics and Grafana dashboards	2026-03-31 19:01:28.11178+00	2026-04-01 04:01:28.11178+00	32400	t	25000	225000	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
c2000000-0000-0000-0000-000000000018	a1000000-0000-0000-0000-000000000002	e1000000-0000-0000-0000-000000000006	a2000000-0000-0000-0000-000000000011	b1000000-0000-0000-0000-000000000005	d1000000-0000-0000-0000-000000000004	Helm charts for frontend services	2026-04-10 19:01:28.11178+00	2026-04-11 03:01:28.11178+00	28800	t	25000	200000	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
c2000000-0000-0000-0000-000000000019	a1000000-0000-0000-0000-000000000002	e1000000-0000-0000-0000-000000000008	a2000000-0000-0000-0000-000000000013	b1000000-0000-0000-0000-000000000004	d1000000-0000-0000-0000-000000000005	AWS Security Hub findings review	2026-04-15 19:01:28.11178+00	2026-04-16 01:01:28.11178+00	21600	t	12000	72000	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
c2000000-0000-0000-0000-000000000020	a1000000-0000-0000-0000-000000000002	e1000000-0000-0000-0000-000000000008	a2000000-0000-0000-0000-000000000014	b1000000-0000-0000-0000-000000000005	d1000000-0000-0000-0000-000000000005	Draft audit report	2026-04-18 19:01:28.11178+00	2026-04-18 23:01:28.11178+00	14400	f	\N	\N	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, email, name, password_hash, instance_role, display_name, email_verified_at, created_at, updated_at) FROM stdin;
72521442-e104-4783-a7d0-0157a489ca1e	patworada2004@gmail.com	Worada Sarakhon	$2b$10$eEQ42rdgzMQOAhYWgMXvtuuZ16Zsy/9D0FBMlVwbwY935iSewsQ1u	ADMIN	\N	\N	2026-04-20 18:48:27.903591+00	2026-04-20 18:48:27.903591+00
b1000000-0000-0000-0000-000000000001	alice@pixelcraft.io	Alice Tanaka	$2b$10$hashedpassword1	ADMIN	Alice	2026-01-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
b1000000-0000-0000-0000-000000000002	bob@pixelcraft.io	Bob Srisuk	$2b$10$hashedpassword2	USER	Bob	2026-01-25 19:01:28.11178+00	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
b1000000-0000-0000-0000-000000000003	charlie@pixelcraft.io	Charlie Nakamura	$2b$10$hashedpassword3	USER	Charlie	2026-01-30 19:01:28.11178+00	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
b1000000-0000-0000-0000-000000000004	diana@devops.io	Diana Lee	$2b$10$hashedpassword4	USER	Diana	2026-02-09 19:01:28.11178+00	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
b1000000-0000-0000-0000-000000000005	evan@devops.io	Evan Wirawan	$2b$10$hashedpassword5	USER	Evan	2026-02-19 19:01:28.11178+00	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
b1000000-0000-0000-0000-000000000006	fiona@pixelcraft.io	Fiona Chen	$2b$10$hashedpassword6	USER	Fiona	2026-03-21 19:01:28.11178+00	2026-04-20 19:01:28.11178+00	2026-04-20 19:01:28.11178+00
8e606d22-8589-4965-be20-e7c5ba934208	65070203@kmitl.ac.th	sarakhon	$2b$10$uQxunJTCoSNa.Vi3gny.RevW0VR2vlAHOvNdA1lNz4TYOGLr8Fbm6	USER	\N	\N	2026-04-21 13:51:02.050967+00	2026-04-21 13:51:02.050967+00
\.


--
-- Name: migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.migrations_id_seq', 1, false);


--
-- Name: schema_ardine_short_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.schema_ardine_short_id_seq', 15, true);


--
-- Name: clients clients_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_pkey PRIMARY KEY (id);


--
-- Name: invites invites_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invites
    ADD CONSTRAINT invites_pkey PRIMARY KEY (id);


--
-- Name: invites invites_team_id_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invites
    ADD CONSTRAINT invites_team_id_email_key UNIQUE (team_id, email);


--
-- Name: invites invites_token_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invites
    ADD CONSTRAINT invites_token_key UNIQUE (token);


--
-- Name: invoice_items invoice_items_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice_items
    ADD CONSTRAINT invoice_items_pkey PRIMARY KEY (id);


--
-- Name: invoice_time_entries invoice_time_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice_time_entries
    ADD CONSTRAINT invoice_time_entries_pkey PRIMARY KEY (id);


--
-- Name: invoice_time_entries invoice_time_entries_time_entry_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice_time_entries
    ADD CONSTRAINT invoice_time_entries_time_entry_id_key UNIQUE (time_entry_id);


--
-- Name: invoices invoices_invoice_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_invoice_number_key UNIQUE (invoice_number);


--
-- Name: invoices invoices_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_pkey PRIMARY KEY (id);


--
-- Name: migrations migrations_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT migrations_name_key UNIQUE (name);


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- Name: project_members project_members_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_members
    ADD CONSTRAINT project_members_pkey PRIMARY KEY (id);


--
-- Name: project_members project_members_project_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_members
    ADD CONSTRAINT project_members_project_id_user_id_key UNIQUE (project_id, user_id);


--
-- Name: project_tasks project_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_tasks
    ADD CONSTRAINT project_tasks_pkey PRIMARY KEY (id);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: schema_ardine_short schema_ardine_short_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schema_ardine_short
    ADD CONSTRAINT schema_ardine_short_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: task_assignees task_assignees_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_assignees
    ADD CONSTRAINT task_assignees_pkey PRIMARY KEY (id);


--
-- Name: task_assignees task_assignees_task_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_assignees
    ADD CONSTRAINT task_assignees_task_id_user_id_key UNIQUE (task_id, user_id);


--
-- Name: team_memberships team_memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.team_memberships
    ADD CONSTRAINT team_memberships_pkey PRIMARY KEY (id);


--
-- Name: team_memberships team_memberships_team_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.team_memberships
    ADD CONSTRAINT team_memberships_team_id_user_id_key UNIQUE (team_id, user_id);


--
-- Name: teams teams_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (id);


--
-- Name: teams teams_slug_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teams
    ADD CONSTRAINT teams_slug_key UNIQUE (slug);


--
-- Name: time_entries time_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.time_entries
    ADD CONSTRAINT time_entries_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_clients_archived_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_clients_archived_at ON public.clients USING btree (archived_at) WHERE (archived_at IS NOT NULL);


--
-- Name: idx_clients_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_clients_email ON public.clients USING btree (email) WHERE (email IS NOT NULL);


--
-- Name: idx_clients_name_lower; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_clients_name_lower ON public.clients USING btree (lower((name)::text));


--
-- Name: idx_clients_team_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_clients_team_id ON public.clients USING btree (team_id);


--
-- Name: idx_invites_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_invites_email ON public.invites USING btree (email);


--
-- Name: idx_invites_expires_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_invites_expires_at ON public.invites USING btree (expires_at);


--
-- Name: idx_invites_team_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_invites_team_id ON public.invites USING btree (team_id);


--
-- Name: idx_invites_token; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_invites_token ON public.invites USING btree (token);


--
-- Name: idx_invoice_items_invoice_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_invoice_items_invoice_id ON public.invoice_items USING btree (invoice_id);


--
-- Name: idx_invoice_items_team_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_invoice_items_team_id ON public.invoice_items USING btree (team_id);


--
-- Name: idx_invoice_items_time_entry_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_invoice_items_time_entry_id ON public.invoice_items USING btree (time_entry_id);


--
-- Name: idx_invoice_time_entries_invoice_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_invoice_time_entries_invoice_id ON public.invoice_time_entries USING btree (invoice_id);


--
-- Name: idx_invoice_time_entries_invoice_item_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_invoice_time_entries_invoice_item_id ON public.invoice_time_entries USING btree (invoice_item_id);


--
-- Name: idx_invoice_time_entries_time_entry_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_invoice_time_entries_time_entry_id ON public.invoice_time_entries USING btree (time_entry_id);


--
-- Name: idx_invoices_client_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_invoices_client_id ON public.invoices USING btree (client_id);


--
-- Name: idx_invoices_invoice_number; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_invoices_invoice_number ON public.invoices USING btree (invoice_number);


--
-- Name: idx_invoices_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_invoices_status ON public.invoices USING btree (status);


--
-- Name: idx_invoices_team_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_invoices_team_id ON public.invoices USING btree (team_id);


--
-- Name: idx_project_members_project_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_project_members_project_id ON public.project_members USING btree (project_id);


--
-- Name: idx_project_members_team_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_project_members_team_id ON public.project_members USING btree (team_id);


--
-- Name: idx_project_members_team_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_project_members_team_user ON public.project_members USING btree (team_id, user_id);


--
-- Name: idx_project_members_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_project_members_user_id ON public.project_members USING btree (user_id);


--
-- Name: idx_project_tasks_project_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_project_tasks_project_id ON public.project_tasks USING btree (project_id);


--
-- Name: idx_project_tasks_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_project_tasks_status ON public.project_tasks USING btree (team_id, status);


--
-- Name: idx_project_tasks_tags; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_project_tasks_tags ON public.project_tasks USING gin (tags);


--
-- Name: idx_project_tasks_team_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_project_tasks_team_id ON public.project_tasks USING btree (team_id);


--
-- Name: idx_projects_client_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_client_id ON public.projects USING btree (client_id);


--
-- Name: idx_projects_client_id_team; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_client_id_team ON public.projects USING btree (team_id, client_id);


--
-- Name: idx_projects_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_status ON public.projects USING btree (team_id, status);


--
-- Name: idx_projects_tags; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_tags ON public.projects USING gin (tags);


--
-- Name: idx_projects_team_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_team_id ON public.projects USING btree (team_id);


--
-- Name: idx_sessions_expires_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sessions_expires_at ON public.sessions USING btree (expires_at);


--
-- Name: idx_sessions_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_sessions_user_id ON public.sessions USING btree (user_id);


--
-- Name: idx_task_assignees_task_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_task_assignees_task_id ON public.task_assignees USING btree (task_id);


--
-- Name: idx_task_assignees_team_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_task_assignees_team_id ON public.task_assignees USING btree (team_id);


--
-- Name: idx_task_assignees_team_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_task_assignees_team_user ON public.task_assignees USING btree (team_id, user_id);


--
-- Name: idx_task_assignees_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_task_assignees_user_id ON public.task_assignees USING btree (user_id);


--
-- Name: idx_team_memberships_role; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_team_memberships_role ON public.team_memberships USING btree (role);


--
-- Name: idx_team_memberships_team_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_team_memberships_team_id ON public.team_memberships USING btree (team_id);


--
-- Name: idx_team_memberships_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_team_memberships_user_id ON public.team_memberships USING btree (user_id);


--
-- Name: idx_teams_slug; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_teams_slug ON public.teams USING btree (slug);


--
-- Name: idx_time_entries_billable; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_time_entries_billable ON public.time_entries USING btree (team_id, billable);


--
-- Name: idx_time_entries_client_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_time_entries_client_id ON public.time_entries USING btree (client_id);


--
-- Name: idx_time_entries_project_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_time_entries_project_id ON public.time_entries USING btree (project_id);


--
-- Name: idx_time_entries_project_started; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_time_entries_project_started ON public.time_entries USING btree (project_id, started_at);


--
-- Name: idx_time_entries_start_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_time_entries_start_time ON public.time_entries USING btree (started_at);


--
-- Name: idx_time_entries_started_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_time_entries_started_at ON public.time_entries USING btree (started_at);


--
-- Name: idx_time_entries_task_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_time_entries_task_id ON public.time_entries USING btree (task_id);


--
-- Name: idx_time_entries_team_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_time_entries_team_id ON public.time_entries USING btree (team_id);


--
-- Name: idx_time_entries_team_started; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_time_entries_team_started ON public.time_entries USING btree (team_id, started_at);


--
-- Name: idx_time_entries_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_time_entries_user_id ON public.time_entries USING btree (user_id);


--
-- Name: idx_time_entries_user_started; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_time_entries_user_started ON public.time_entries USING btree (user_id, started_at);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: idx_users_instance_role; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_instance_role ON public.users USING btree (instance_role);


--
-- Name: unique_client_name_per_team; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX unique_client_name_per_team ON public.clients USING btree (team_id, lower((name)::text));


--
-- Name: unique_project_code_per_team; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX unique_project_code_per_team ON public.projects USING btree (team_id, lower(code)) WHERE (code IS NOT NULL);


--
-- Name: unique_project_name_per_team; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX unique_project_name_per_team ON public.projects USING btree (team_id, lower((name)::text));


--
-- Name: unique_task_name_per_project; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX unique_task_name_per_project ON public.project_tasks USING btree (project_id, lower(name));


--
-- Name: clients update_clients_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_clients_updated_at BEFORE UPDATE ON public.clients FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: invoices update_invoices_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON public.invoices FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: project_members update_project_members_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_project_members_updated_at BEFORE UPDATE ON public.project_members FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: project_tasks update_project_tasks_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_project_tasks_updated_at BEFORE UPDATE ON public.project_tasks FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: projects update_projects_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON public.projects FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: teams update_teams_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_teams_updated_at BEFORE UPDATE ON public.teams FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: time_entries update_time_entries_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_time_entries_updated_at BEFORE UPDATE ON public.time_entries FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: users update_users_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: clients clients_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.teams(id) ON DELETE CASCADE;


--
-- Name: invites invites_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invites
    ADD CONSTRAINT invites_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.teams(id) ON DELETE CASCADE;


--
-- Name: invoice_items invoice_items_invoice_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice_items
    ADD CONSTRAINT invoice_items_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES public.invoices(id) ON DELETE CASCADE;


--
-- Name: invoice_items invoice_items_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice_items
    ADD CONSTRAINT invoice_items_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.teams(id) ON DELETE CASCADE;


--
-- Name: invoice_items invoice_items_time_entry_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice_items
    ADD CONSTRAINT invoice_items_time_entry_id_fkey FOREIGN KEY (time_entry_id) REFERENCES public.time_entries(id) ON DELETE SET NULL;


--
-- Name: invoice_time_entries invoice_time_entries_invoice_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice_time_entries
    ADD CONSTRAINT invoice_time_entries_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES public.invoices(id) ON DELETE CASCADE;


--
-- Name: invoice_time_entries invoice_time_entries_invoice_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice_time_entries
    ADD CONSTRAINT invoice_time_entries_invoice_item_id_fkey FOREIGN KEY (invoice_item_id) REFERENCES public.invoice_items(id) ON DELETE CASCADE;


--
-- Name: invoice_time_entries invoice_time_entries_time_entry_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoice_time_entries
    ADD CONSTRAINT invoice_time_entries_time_entry_id_fkey FOREIGN KEY (time_entry_id) REFERENCES public.time_entries(id) ON DELETE CASCADE;


--
-- Name: invoices invoices_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.clients(id) ON DELETE CASCADE;


--
-- Name: invoices invoices_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.teams(id) ON DELETE CASCADE;


--
-- Name: project_members project_members_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_members
    ADD CONSTRAINT project_members_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: project_members project_members_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_members
    ADD CONSTRAINT project_members_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.teams(id) ON DELETE CASCADE;


--
-- Name: project_members project_members_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_members
    ADD CONSTRAINT project_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: project_tasks project_tasks_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_tasks
    ADD CONSTRAINT project_tasks_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: project_tasks project_tasks_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_tasks
    ADD CONSTRAINT project_tasks_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.teams(id) ON DELETE CASCADE;


--
-- Name: projects projects_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.clients(id) ON DELETE CASCADE;


--
-- Name: projects projects_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.teams(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: task_assignees task_assignees_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_assignees
    ADD CONSTRAINT task_assignees_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.project_tasks(id) ON DELETE CASCADE;


--
-- Name: task_assignees task_assignees_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_assignees
    ADD CONSTRAINT task_assignees_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.teams(id) ON DELETE CASCADE;


--
-- Name: task_assignees task_assignees_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.task_assignees
    ADD CONSTRAINT task_assignees_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: team_memberships team_memberships_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.team_memberships
    ADD CONSTRAINT team_memberships_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.teams(id) ON DELETE CASCADE;


--
-- Name: team_memberships team_memberships_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.team_memberships
    ADD CONSTRAINT team_memberships_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: time_entries time_entries_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.time_entries
    ADD CONSTRAINT time_entries_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.clients(id) ON DELETE CASCADE;


--
-- Name: time_entries time_entries_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.time_entries
    ADD CONSTRAINT time_entries_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: time_entries time_entries_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.time_entries
    ADD CONSTRAINT time_entries_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.project_tasks(id) ON DELETE SET NULL;


--
-- Name: time_entries time_entries_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.time_entries
    ADD CONSTRAINT time_entries_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.teams(id) ON DELETE CASCADE;


--
-- Name: time_entries time_entries_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.time_entries
    ADD CONSTRAINT time_entries_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict nrdVTCPzmkuaM10d5nquxPtFVuo55d7oOEXrFXIFUvxO4VQS7efaBPpKtOKPUjj

