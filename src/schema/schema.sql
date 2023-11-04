
SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

ALTER SCHEMA "public" OWNER TO "postgres";

CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";

CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";

SET default_tablespace = '';

SET default_table_access_method = "heap";

CREATE TABLE "public"."userHasRoom" (
    "room" bigint,
    "user" "uuid"
);

ALTER TABLE "public"."userHasRoom" OWNER TO "postgres";

CREATE FUNCTION "public"."getusersbyroom"() RETURNS SETOF "public"."userHasRoom"
    LANGUAGE "sql"
    AS $$
  select * from "userHasRoom"
  group by room, "userHasRoom".user
$$;

ALTER FUNCTION "public"."getusersbyroom"() OWNER TO "postgres";

CREATE FUNCTION "public"."getusersbyrooms"() RETURNS "void"
    LANGUAGE "sql"
    AS $$
  select * from "userHasRoom"
  inner join profiles on "userHasRoom".user = profiles.id
$$;

ALTER FUNCTION "public"."getusersbyrooms"() OWNER TO "postgres";

CREATE TABLE "public"."images" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "url" character varying,
    "message_id" bigint,
    "message_room_id" bigint,
    "message_user_id" "uuid"
);

ALTER TABLE "public"."images" OWNER TO "postgres";

ALTER TABLE "public"."images" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."images_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE "public"."message" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "content" "text" NOT NULL,
    "room" bigint NOT NULL,
    "user" "uuid" NOT NULL,
    "view" boolean DEFAULT false NOT NULL,
    "isBlocked" boolean DEFAULT false NOT NULL
);

ALTER TABLE ONLY "public"."message" REPLICA IDENTITY FULL;

ALTER TABLE "public"."message" OWNER TO "postgres";

ALTER TABLE "public"."message" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."message_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE "public"."profiles" (
    "id" "uuid" NOT NULL,
    "updated_at" timestamp with time zone,
    "username" "text" NOT NULL,
    "avatar_url" "text" DEFAULT ''::"text" NOT NULL,
    "email" "text",
    "about" "text" DEFAULT ''::"text" NOT NULL,
    "phone" character varying DEFAULT ''::character varying NOT NULL,
    CONSTRAINT "username_length" CHECK (("char_length"("username") >= 3))
);

ALTER TABLE "public"."profiles" OWNER TO "postgres";

CREATE TABLE "public"."room" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);

ALTER TABLE "public"."room" OWNER TO "postgres";

ALTER TABLE "public"."room" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."room_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE "public"."userHasBlockedRoom" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "blocking_user_id" "uuid" NOT NULL,
    "room_id" bigint NOT NULL
);

ALTER TABLE "public"."userHasBlockedRoom" OWNER TO "postgres";

ALTER TABLE "public"."userHasBlockedRoom" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."userHasBlocked_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

ALTER TABLE ONLY "public"."images"
    ADD CONSTRAINT "images_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."message"
    ADD CONSTRAINT "message_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_email_key" UNIQUE ("email");

ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."room"
    ADD CONSTRAINT "room_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."userHasBlockedRoom"
    ADD CONSTRAINT "userHasBlocked_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."images"
    ADD CONSTRAINT "images_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES "public"."message"("id");

ALTER TABLE ONLY "public"."images"
    ADD CONSTRAINT "images_message_room_id_fkey" FOREIGN KEY ("message_room_id") REFERENCES "public"."room"("id");

ALTER TABLE ONLY "public"."images"
    ADD CONSTRAINT "images_message_user_id_fkey" FOREIGN KEY ("message_user_id") REFERENCES "public"."profiles"("id");

ALTER TABLE ONLY "public"."message"
    ADD CONSTRAINT "message_room_fkey" FOREIGN KEY ("room") REFERENCES "public"."room"("id");

ALTER TABLE ONLY "public"."message"
    ADD CONSTRAINT "message_user_fkey" FOREIGN KEY ("user") REFERENCES "public"."profiles"("id");

ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id");

ALTER TABLE ONLY "public"."userHasBlockedRoom"
    ADD CONSTRAINT "userHasBlockedRoom_blocking_user_id_fkey" FOREIGN KEY ("blocking_user_id") REFERENCES "public"."profiles"("id");

ALTER TABLE ONLY "public"."userHasBlockedRoom"
    ADD CONSTRAINT "userHasBlockedRoom_room_id_fkey" FOREIGN KEY ("room_id") REFERENCES "public"."room"("id");

ALTER TABLE ONLY "public"."userHasRoom"
    ADD CONSTRAINT "userHasRoom_room_fkey" FOREIGN KEY ("room") REFERENCES "public"."room"("id");

ALTER TABLE ONLY "public"."userHasRoom"
    ADD CONSTRAINT "userHasRoom_user_fkey" FOREIGN KEY ("user") REFERENCES "public"."profiles"("id");

CREATE POLICY "Authenticated users can insert images" ON "public"."images" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));

CREATE POLICY "Create a new message for authenticated users only" ON "public"."message" FOR INSERT WITH CHECK (("auth"."role"() = 'authenticated'::"text"));

CREATE POLICY "Create new rooms with users for authenticated users only" ON "public"."userHasRoom" FOR INSERT WITH CHECK (("auth"."role"() = 'authenticated'::"text"));

CREATE POLICY "Enable delete for users based on user_id" ON "public"."userHasBlockedRoom" FOR DELETE TO "authenticated" USING (("auth"."uid"() = "blocking_user_id"));

CREATE POLICY "Enable insert for authenticated users only" ON "public"."userHasBlockedRoom" FOR INSERT TO "authenticated" WITH CHECK (true);

CREATE POLICY "Enable select for users based on user_id" ON "public"."userHasBlockedRoom" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "blocking_user_id"));

CREATE POLICY "Enable update for users base on authentication" ON "public"."message" FOR UPDATE USING (("auth"."role"() = 'authenticated'::"text")) WITH CHECK (("auth"."role"() = 'authenticated'::"text"));

CREATE POLICY "Insert a new room for authenticated users only" ON "public"."room" FOR INSERT WITH CHECK (("auth"."role"() = 'authenticated'::"text"));

CREATE POLICY "Public profiles are viewable by everyone." ON "public"."profiles" FOR SELECT USING (true);

CREATE POLICY "Select room for authenticated users only" ON "public"."room" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));

CREATE POLICY "Select room for authenticated users to see the different users" ON "public"."userHasRoom" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));

CREATE POLICY "User can delete only their own messages" ON "public"."message" FOR DELETE USING ((("auth"."role"() = 'authenticated'::"text") AND ("auth"."uid"() = "user")));

CREATE POLICY "Users can delete the images " ON "public"."images" FOR DELETE USING ((("auth"."role"() = 'authenticated'::"text") AND ("auth"."uid"() = "message_user_id")));

CREATE POLICY "Users can insert their own profile." ON "public"."profiles" FOR INSERT WITH CHECK (("auth"."uid"() = "id"));

CREATE POLICY "Users can only see messages when authenticated" ON "public"."message" FOR SELECT USING (("auth"."role"() = 'authenticated'::"text"));

CREATE POLICY "Users can update own profile." ON "public"."profiles" FOR UPDATE USING (("auth"."uid"() = "id"));

CREATE POLICY "Users can upload their images" ON "public"."images" FOR INSERT WITH CHECK ((("auth"."role"() = 'authenticated'::"text") AND ("auth"."uid"() = "message_user_id")));

ALTER TABLE "public"."images" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."message" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."room" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."userHasBlockedRoom" ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."userHasRoom" ENABLE ROW LEVEL SECURITY;

REVOKE USAGE ON SCHEMA "public" FROM PUBLIC;
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

GRANT ALL ON TABLE "public"."userHasRoom" TO "anon";
GRANT ALL ON TABLE "public"."userHasRoom" TO "authenticated";
GRANT ALL ON TABLE "public"."userHasRoom" TO "service_role";

GRANT ALL ON FUNCTION "public"."getusersbyroom"() TO "anon";
GRANT ALL ON FUNCTION "public"."getusersbyroom"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."getusersbyroom"() TO "service_role";

GRANT ALL ON FUNCTION "public"."getusersbyrooms"() TO "anon";
GRANT ALL ON FUNCTION "public"."getusersbyrooms"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."getusersbyrooms"() TO "service_role";

GRANT ALL ON TABLE "public"."images" TO "anon";
GRANT ALL ON TABLE "public"."images" TO "authenticated";
GRANT ALL ON TABLE "public"."images" TO "service_role";

GRANT ALL ON SEQUENCE "public"."images_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."images_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."images_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."message" TO "anon";
GRANT ALL ON TABLE "public"."message" TO "authenticated";
GRANT ALL ON TABLE "public"."message" TO "service_role";

GRANT ALL ON SEQUENCE "public"."message_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."message_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."message_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";

GRANT ALL ON TABLE "public"."room" TO "anon";
GRANT ALL ON TABLE "public"."room" TO "authenticated";
GRANT ALL ON TABLE "public"."room" TO "service_role";

GRANT ALL ON SEQUENCE "public"."room_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."room_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."room_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."userHasBlockedRoom" TO "anon";
GRANT ALL ON TABLE "public"."userHasBlockedRoom" TO "authenticated";
GRANT ALL ON TABLE "public"."userHasBlockedRoom" TO "service_role";

GRANT ALL ON SEQUENCE "public"."userHasBlocked_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."userHasBlocked_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."userHasBlocked_id_seq" TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "service_role";

RESET ALL;