*************************** 1. row ***************************
       Table: detil_kepengurusan
Create Table: CREATE TABLE `detil_kepengurusan` (
  `id_detil_kepengurusan` int NOT NULL AUTO_INCREMENT,
  `kepengurusan_id` int DEFAULT '0',
  `kode_wilayah` varchar(128) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `pribadi_id` int DEFAULT '0',
  `jabatan_id` int DEFAULT '0',
  `jabatan_pn` varchar(256) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `is_active` tinyint DEFAULT '1',
  `OldKodeWilayah` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL,
  `IdWilayah` int DEFAULT NULL,
  `created` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_detil_kepengurusan`),
  KEY `detil_pribadi_FK` (`pribadi_id`),
  KEY `detil_jabatan_FK` (`jabatan_id`),
  KEY `detil_kepengurusan_FK` (`kepengurusan_id`),
  CONSTRAINT `detil_jabatan_FK` FOREIGN KEY (`jabatan_id`) REFERENCES `jabatan` (`id_jabatan`),
  CONSTRAINT `detil_kepengurusan_FK` FOREIGN KEY (`kepengurusan_id`) REFERENCES `kepengurusan` (`id_kepengurusan`),
  CONSTRAINT `detil_pribadi_FK` FOREIGN KEY (`pribadi_id`) REFERENCES `pribadi` (`idpribadi`)
) ENGINE=InnoDB AUTO_INCREMENT=25367 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci
*************************** 1. row ***************************
       Table: jabatan
Create Table: CREATE TABLE `jabatan` (
  `id_jabatan` int NOT NULL AUTO_INCREMENT,
  `nama` varchar(512) DEFAULT NULL,
  `json_jabatan` text,
  `level_id` int DEFAULT NULL COMMENT '1 Pimpinan Pusat\\r\\n2 Pimpinan Wilayah\\r\\n3 Pimpinan Cabang / Istimewa\\r\\n4 Pimpinan Anak Cabang\\r\\n5 Pimpinan Ranting',
  `created` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_jabatan`),
  KEY `jabatan_level_FK` (`level_id`),
  CONSTRAINT `jabatan_level_FK` FOREIGN KEY (`level_id`) REFERENCES `level` (`id_level`)
) ENGINE=InnoDB AUTO_INCREMENT=136 DEFAULT CHARSET=utf8mb3
*************************** 1. row ***************************
       Table: kabupaten
Create Table: CREATE TABLE `kabupaten` (
  `id` int NOT NULL AUTO_INCREMENT,
  `idParent` int DEFAULT NULL,
  `kodeShort` varchar(20) DEFAULT NULL,
  `kodeFull` varchar(20) DEFAULT NULL,
  `kode` varchar(20) DEFAULT NULL,
  `nama` varchar(150) DEFAULT NULL,
  `oldIdDb` varchar(20) DEFAULT NULL,
  `oldId` varchar(20) DEFAULT NULL,
  `oldNama` varchar(150) DEFAULT NULL,
  `oldKodeWilayahPn` varchar(20) DEFAULT NULL,
  `IsPcKhusus` bit(1) DEFAULT b'0',
  `kodefull_pecahan` varchar(20) DEFAULT NULL COMMENT 'kodefull kabupaten asal',
  PRIMARY KEY (`id`),
  KEY `kabupaten_prov_FK` (`idParent`),
  CONSTRAINT `kabupaten_prov_FK` FOREIGN KEY (`idParent`) REFERENCES `provinsi` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=528 DEFAULT CHARSET=utf8mb3 COMMENT='diambil dari sini 30 Okt 2021\r\nhttps://github.com/cahyadsn/wilayah'
*************************** 1. row ***************************
       Table: kecamatan
Create Table: CREATE TABLE `kecamatan` (
  `id` int NOT NULL AUTO_INCREMENT,
  `idParent` int DEFAULT NULL,
  `kodeShort` varchar(20) DEFAULT NULL,
  `kodeFull` varchar(20) DEFAULT NULL,
  `kode` varchar(20) DEFAULT NULL,
  `nama` varchar(150) DEFAULT NULL,
  `oldIdDb` varchar(20) DEFAULT NULL,
  `oldId` varchar(20) DEFAULT NULL,
  `oldNama` varchar(150) DEFAULT NULL,
  `oldKodeWilayahPn` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `kecamatan_kabupaten_FK` (`idParent`),
  CONSTRAINT `kecamatan_kabupaten_FK` FOREIGN KEY (`idParent`) REFERENCES `kabupaten` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7247 DEFAULT CHARSET=utf8mb3 COMMENT='diambil dari sini 30 Okt 2021\r\nhttps://github.com/cahyadsn/wilayah'
*************************** 1. row ***************************
       Table: kelurahan
Create Table: CREATE TABLE `kelurahan` (
  `id` int NOT NULL AUTO_INCREMENT,
  `idParent` int DEFAULT NULL,
  `kodeShort` varchar(20) DEFAULT NULL,
  `kodeFull` varchar(20) DEFAULT NULL,
  `kode` varchar(20) DEFAULT NULL,
  `nama` varchar(150) DEFAULT NULL,
  `oldIdDb` varchar(20) DEFAULT NULL,
  `oldId` varchar(20) DEFAULT NULL,
  `oldNama` varchar(150) DEFAULT NULL,
  `oldKodeWilayahPn` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `kelurahan_kecamatan_FK` (`idParent`),
  CONSTRAINT `kelurahan_kecamatan_FK` FOREIGN KEY (`idParent`) REFERENCES `kecamatan` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=81076 DEFAULT CHARSET=utf8mb3 COMMENT='diambil dari sini 30 Okt 2021\r\nhttps://github.com/cahyadsn/wilayah'
*************************** 1. row ***************************
       Table: kepengurusan
Create Table: CREATE TABLE `kepengurusan` (
  `id_kepengurusan` int NOT NULL AUTO_INCREMENT,
  `level_id` int DEFAULT '0',
  `nama_kepengurusan` varchar(1024) DEFAULT NULL,
  `kode_wilayah` varchar(128) DEFAULT NULL,
  `periode_mulai` datetime DEFAULT NULL,
  `periode_selesai` datetime DEFAULT NULL,
  `is_active` tinyint DEFAULT '0',
  `is_pengurus` tinyint DEFAULT '0',
  `json_kepengurusan` text,
  `url_file` text,
  `OldKodeWilayah` varchar(100) DEFAULT NULL,
  `IdWilayah` int DEFAULT NULL,
  `created` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_kepengurusan`),
  KEY `kepengurusan_level_FK` (`level_id`),
  CONSTRAINT `kepengurusan_level_FK` FOREIGN KEY (`level_id`) REFERENCES `level` (`id_level`)
) ENGINE=InnoDB AUTO_INCREMENT=88795 DEFAULT CHARSET=utf8mb3
*************************** 1. row ***************************
       Table: koneksi_eksternal
Create Table: CREATE TABLE `koneksi_eksternal` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nama` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'nama aplikasinya / sistem',
  `url` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `isprod` tinyint DEFAULT '0',
  `isenabled` tinyint DEFAULT '0',
  `pic` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `created` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='table untuk simpan koneksi eksternal ke backend services'
*************************** 1. row ***************************
       Table: latihan
Create Table: CREATE TABLE `latihan` (
  `id_latihan` int NOT NULL AUTO_INCREMENT,
  `pelatih_id` int DEFAULT NULL COMMENT 'FK ke tabel pribadi',
  `kecamatan_id` int DEFAULT '0' COMMENT 'FK ke tabel kecamatan',
  `padepokan_id` int DEFAULT NULL COMMENT 'FK ke tabel padepokan',
  `sabuk` varchar(256) DEFAULT NULL,
  `tgl_mulai` datetime DEFAULT NULL,
  `tgl_selesai` datetime DEFAULT NULL,
  `latlong` varchar(512) DEFAULT NULL,
  `is_active` tinyint DEFAULT '0',
  `created` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_latihan`),
  KEY `latihan_pribadi_FK` (`pelatih_id`),
  KEY `latihan_kecamatan_FK` (`kecamatan_id`),
  KEY `latihan_padepokan_FK` (`padepokan_id`),
  CONSTRAINT `latihan_kecamatan_FK` FOREIGN KEY (`kecamatan_id`) REFERENCES `kecamatan` (`id`),
  CONSTRAINT `latihan_padepokan_FK` FOREIGN KEY (`padepokan_id`) REFERENCES `padepokan` (`id_padepokan`),
  CONSTRAINT `latihan_pribadi_FK` FOREIGN KEY (`pelatih_id`) REFERENCES `pribadi` (`idpribadi`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='tabel lokasi latihan ini'
*************************** 1. row ***************************
       Table: level
Create Table: CREATE TABLE `level` (
  `id_level` int NOT NULL AUTO_INCREMENT,
  `tingkat` varchar(256) DEFAULT NULL,
  `nama` varchar(256) DEFAULT NULL,
  `json_level` text,
  `created` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_level`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb3
*************************** 1. row ***************************
       Table: padepokan
Create Table: CREATE TABLE `padepokan` (
  `id_padepokan` int NOT NULL AUTO_INCREMENT,
  `nama` varchar(256) DEFAULT NULL,
  `alamat` varchar(1024) DEFAULT NULL,
  `telp` varchar(256) DEFAULT NULL,
  `created` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_padepokan`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3
*************************** 1. row ***************************
       Table: penomoran
Create Table: CREATE TABLE `penomoran` (
  `IdPenomoran` int NOT NULL AUTO_INCREMENT,
  `IdPribadi` int DEFAULT NULL,
  `IdProv` int DEFAULT NULL,
  `IdKota` int DEFAULT NULL,
  `NoUrut` int DEFAULT NULL,
  `KodeKotaPn` varchar(20) DEFAULT NULL,
  `NoKta` varchar(15) DEFAULT NULL,
  `Created` datetime DEFAULT CURRENT_TIMESTAMP,
  `Updated` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`IdPenomoran`),
  KEY `penomoran_pribadi_FK` (`IdPribadi`),
  KEY `penomoran_kota_FK` (`IdKota`),
  KEY `penomoran_provinsi_FK` (`IdProv`),
  CONSTRAINT `penomoran_kota_FK` FOREIGN KEY (`IdKota`) REFERENCES `kabupaten` (`id`),
  CONSTRAINT `penomoran_pribadi_FK` FOREIGN KEY (`IdPribadi`) REFERENCES `pribadi` (`idpribadi`),
  CONSTRAINT `penomoran_provinsi_FK` FOREIGN KEY (`IdProv`) REFERENCES `provinsi` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=192301 DEFAULT CHARSET=utf8mb3
*************************** 1. row ***************************
       Table: permission
Create Table: CREATE TABLE `permission` (
  `id` int NOT NULL AUTO_INCREMENT,
  `parent` int DEFAULT '0',
  `icon` varchar(50) DEFAULT NULL,
  `title` varchar(75) DEFAULT NULL,
  `description` varchar(150) DEFAULT NULL,
  `url` varchar(150) DEFAULT NULL,
  `custom` varchar(150) DEFAULT NULL,
  `priority` int DEFAULT '0' COMMENT 'prioritas urutan menu backend 100 on top',
  `is_active` int DEFAULT '0' COMMENT '0: In-Active; 1: Active;',
  `action` int NOT NULL DEFAULT '1' COMMENT '0 inot show in menu, 1 show in menu',
  `created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3
*************************** 1. row ***************************
       Table: pribadi
Create Table: CREATE TABLE `pribadi` (
  `idpribadi` int NOT NULL AUTO_INCREMENT,
  `publicid` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `nama` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `tempat_lahir` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `tgl_lahir` datetime DEFAULT NULL,
  `kelamin` varchar(2) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `gol_darah` varchar(4) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `kelurahan_ktp` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL COMMENT 'FK ke tabel kelurahan',
  `kelurahan_domisili` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL COMMENT 'FK ke tabel kelurahan',
  `agama` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `stat_kawin` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `no_kk` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `no_ktp` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `is_wni` tinyint(1) DEFAULT '1',
  `json_alamat` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
  `json_pendidikan` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
  `json_pekerjaan` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
  `json_perguruan` text,
  `is_pelatih` tinyint(1) DEFAULT '0',
  `is_pengurus` tinyint(1) DEFAULT '0',
  `is_verified` tinyint(1) DEFAULT '0',
  `is_admin` tinyint(1) DEFAULT '0',
  `jabatan_pn` varchar(1024) DEFAULT 'Unverified',
  `verified_date` datetime DEFAULT NULL,
  `verifier` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `email` varchar(256) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `nokta` varchar(15) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `nokta_lama` varchar(25) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `url_ktp` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `url_foto` varchar(150) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `nohp` varchar(20) DEFAULT NULL,
  `is_email_first_login` tinyint DEFAULT '1',
  `scopedata` varchar(500) DEFAULT NULL,
  `IdKelurahanKtp` int DEFAULT NULL,
  `IdKabupatenDomisili` int DEFAULT NULL,
  `IdKelurahanDomisili` int DEFAULT NULL,
  `OldKelurahanKtp` varchar(50) DEFAULT NULL,
  `OldKelurahanDomisili` varchar(50) DEFAULT NULL,
  `KabupatenKtp` varchar(50) DEFAULT NULL,
  `KabupatenDomisili` varchar(50) DEFAULT NULL,
  `created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `resetby` varchar(64) DEFAULT NULL,
  `resetdate` datetime DEFAULT NULL,
  PRIMARY KEY (`idpribadi`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=227846 DEFAULT CHARSET=utf8mb3
*************************** 1. row ***************************
       Table: provinsi
Create Table: CREATE TABLE `provinsi` (
  `id` int NOT NULL AUTO_INCREMENT,
  `kodeShort` varchar(20) DEFAULT NULL,
  `kodeFull` varchar(20) DEFAULT NULL,
  `kode` varchar(20) DEFAULT NULL,
  `nama` varchar(150) DEFAULT NULL,
  `oldIdDb` varchar(20) DEFAULT NULL,
  `oldId` varchar(20) DEFAULT NULL,
  `oldNama` varchar(150) DEFAULT NULL,
  `oldKodeWilayahPn` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=36 DEFAULT CHARSET=utf8mb3 COMMENT='diambil dari sini 30 Okt 2021\r\nhttps://github.com/cahyadsn/wilayah'
*************************** 1. row ***************************
       Table: roles
Create Table: CREATE TABLE `roles` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(75) NOT NULL,
  `is_deleted` int DEFAULT '0',
  `is_locked` int DEFAULT '0',
  `created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb3
*************************** 1. row ***************************
       Table: roles_menu
Create Table: CREATE TABLE `roles_menu` (
  `Id` int NOT NULL AUTO_INCREMENT,
  `IdRoles` int NOT NULL,
  `JsonMenu` text,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
*************************** 1. row ***************************
       Table: roles_permission
Create Table: CREATE TABLE `roles_permission` (
  `roles_id` int NOT NULL,
  `permission_id` int NOT NULL,
  `created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`roles_id`,`permission_id`),
  KEY `fk_group_idx` (`roles_id`),
  KEY `fk_permission_idx` (`permission_id`),
  CONSTRAINT `fk_group2` FOREIGN KEY (`roles_id`) REFERENCES `roles` (`id`),
  CONSTRAINT `fk_permission_group2` FOREIGN KEY (`permission_id`) REFERENCES `permission` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3
*************************** 1. row ***************************
       Table: temp_updatefoto
Create Table: CREATE TABLE `temp_updatefoto` (
  `idpribadi` int NOT NULL AUTO_INCREMENT,
  `url_foto` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `url_ktp` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `url_foto_new` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `url_ktp_new` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `done_migrasi` binary(1) DEFAULT '0',
  `done_create_url` binary(1) DEFAULT '0',
  PRIMARY KEY (`idpribadi`)
) ENGINE=InnoDB AUTO_INCREMENT=182085 DEFAULT CHARSET=latin1
*************************** 1. row ***************************
       Table: user
Create Table: CREATE TABLE `user` (
  `iduser` int NOT NULL AUTO_INCREMENT,
  `idpribadi` int DEFAULT NULL,
  `iduser_db_lama` varchar(128) DEFAULT NULL,
  `username` varchar(1024) DEFAULT NULL,
  `surname` varchar(1024) DEFAULT NULL,
  `lastname` varchar(1024) DEFAULT NULL,
  `fullname` varchar(1024) DEFAULT NULL,
  `email` varchar(1024) DEFAULT NULL,
  `password` varchar(1024) DEFAULT NULL,
  `isactive` int DEFAULT '1',
  `googleid` varchar(1024) DEFAULT NULL,
  `facebookid` varchar(1024) DEFAULT NULL,
  `lastlogin` datetime DEFAULT NULL,
  `created` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated` datetime DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`iduser`)
) ENGINE=MyISAM AUTO_INCREMENT=111710 DEFAULT CHARSET=utf8mb3
*************************** 1. row ***************************
       Table: user_roles
Create Table: CREATE TABLE `user_roles` (
  `iduserroles` int NOT NULL AUTO_INCREMENT,
  `iduser` int NOT NULL,
  `idroles` int NOT NULL DEFAULT '4' COMMENT 'default isinya 4 (role publik)',
  `created` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`iduserroles`)
) ENGINE=MyISAM AUTO_INCREMENT=111710 DEFAULT CHARSET=utf8mb3

=== TABLE: level ===
id_level	tingkat	nama	json_level	created	updated
1	nasional	Pimpinan Pusat	NULL	2021-05-09 19:38:18	NULL
2	provinsi	Pimpinan Wilayah	NULL	2021-05-09 19:38:29	NULL
3	kabkota	Pimpinan Cabang	NULL	2021-05-09 19:38:43	NULL
4	luarnegeri	Pimpinan Cabang Istimewa	NULL	2021-05-09 19:38:55	NULL
5	kecamatan	Pimpinan Anak Cabang	NULL	2021-05-09 19:39:43	NULL
6	kelurahandesa	Pimpinan Ranting	NULL	2021-05-09 19:40:00	NULL

=== TABLE: provinsi ===
id	kodeShort	kodeFull	kode	nama	oldIdDb	oldId	oldNama	oldKodeWilayahPn
1	11	11	11	ACEH	NULL	11	ACEH	01
2	12	12	12	SUMATERA UTARA	NULL	12	SUMATERA UTARA	02
3	13	13	13	SUMATERA BARAT	NULL	13	SUMATERA BARAT	03
4	14	14	14	RIAU	NULL	14	RIAU	04
5	15	15	15	JAMBI	NULL	15	JAMBI	06
6	16	16	16	SUMATERA SELATAN	NULL	16	SUMATERA SELATAN	08
7	17	17	17	BENGKULU	NULL	17	BENGKULU	07
8	18	18	18	LAMPUNG	NULL	18	LAMPUNG	10
9	19	19	19	KEPULAUAN BANGKA BELITUNG	NULL	19	KEPULAUAN BANGKA BELITUNG	09
10	21	21	21	KEPULAUAN RIAU	NULL	21	KEPULAUAN RIAU	05

=== TABLE: kabupaten ===
id	idParent	kodeShort	kodeFull	kode	nama	oldIdDb	oldId	oldNama	oldKodeWilayahPn	IsPcKhusus	kodefull_pecahan
1	1	01	1101	11.01	KABUPATEN ACEH SELATAN	NULL	1103	KABUPATEN ACEH SELATAN	05	\0	NULL
2	1	02	1102	11.02	KABUPATEN ACEH TENGGARA	NULL	1104	KABUPATEN ACEH TENGGARA	09	\0	NULL
3	1	03	1103	11.03	KABUPATEN ACEH TIMUR	NULL	1105	KABUPATEN ACEH TIMUR	10	\0	NULL
4	1	04	1104	11.04	KABUPATEN ACEH TENGAH	NULL	1106	KABUPATEN ACEH TENGAH	08	\0	NULL
5	1	05	1105	11.05	KABUPATEN ACEH BARAT	NULL	1107	KABUPATEN ACEH BARAT	01	\0	NULL
6	1	06	1106	11.06	KABUPATEN ACEH BESAR	NULL	1108	KABUPATEN ACEH BESAR	03	\0	NULL
7	1	07	1107	11.07	KABUPATEN PIDIE	NULL	1109	KABUPATEN PIDIE	16	\0	NULL
8	1	08	1108	11.08	KABUPATEN ACEH UTARA	NULL	1111	KABUPATEN ACEH UTARA	11	\0	NULL
9	1	09	1109	11.09	KABUPATEN SIMEULUE	NULL	1101	KABUPATEN SIMEULUE	18	\0	NULL
10	1	10	1110	11.10	KABUPATEN ACEH SINGKIL	NULL	1102	KABUPATEN ACEH SINGKIL	06	\0	NULL

=== TABLE: kecamatan ===
id	idParent	kodeShort	kodeFull	kode	nama	oldIdDb	oldId	oldNama	oldKodeWilayahPn
1	1	01	110101	11.01.01	Bakongan	NULL	1103020	BAKONGAN	NULL
2	1	02	110102	11.01.02	Kluet Utara	NULL	1103040	KLUET UTARA	NULL
3	1	03	110103	11.01.03	Kluet Selatan	NULL	1103030	KLUET SELATAN	NULL
4	1	04	110104	11.01.04	Labuhan Haji	NULL	1103090	LABUHAN HAJI	NULL
5	1	05	110105	11.01.05	Meukek	NULL	1103080	MEUKEK	NULL
6	1	07	110107	11.01.07	Sawang	NULL	1103070	SAWANG	NULL
7	1	09	110109	11.01.09	Trumon	NULL	1103010	TRUMON	NULL
8	1	11	110111	11.01.11	Labuhan Haji Timur	NULL	1103091	LABUHAN HAJI TIMUR	NULL
9	1	12	110112	11.01.12	Labuhan Haji Barat	NULL	1103092	LABUHAN HAJI BARAT	NULL
10	1	13	110113	11.01.13	Kluet Tengah	NULL	1103042	KLUET TENGAH	NULL

=== TABLE: kelurahan ===
id	idParent	kodeShort	kodeFull	kode	nama	oldIdDb	oldId	oldNama	oldKodeWilayahPn
1	143	2008	1109072008	11.09.07.2008	Latiung	NULL	1101010001	LATIUNG	NULL
2	143	2011	1109072011	11.09.07.2011	Labuhan Bajau	NULL	1101010002	LABUHAN BAJAU	NULL
3	143	2002	1109072002	11.09.07.2002	Suak Lamatan	NULL	1101010003	SUAK LAMATAN	NULL
4	143	2013	1109072013	11.09.07.2013	Ana Ao	NULL	1101010004	ANA AO	NULL
5	143	2014	1109072014	11.09.07.2014	Lataling	NULL	1101010005	LATALING	NULL
6	143	2007	1109072007	11.09.07.2007	Badegong	NULL	1101010007	BADEGONG	NULL
7	143	2006	1109072006	11.09.07.2006	Kebun Baru	NULL	1101010008	KEBUN BARU	NULL
8	143	2005	1109072005	11.09.07.2005	Ulul Mayang	NULL	1101010009	ULUL MAYANG	NULL
9	143	2009	1109072009	11.09.07.2009	Pasir Tinggi	NULL	1101010010	PASIR TINGGI	NULL
10	143	2010	1109072010	11.09.07.2010	Labuhan Jaya	NULL	1101010011	LABUHAN JAYA	NULL

=== TABLE: padepokan ===

=== TABLE: jabatan ===
id_jabatan	nama	json_jabatan	level_id	created	updated
1	Anggota	NULL	1	2021-05-09 19:48:19	NULL
2	Pelindung	NULL	1	2021-05-09 19:48:19	NULL
3	Dewan Pembina	NULL	1	2021-05-09 19:48:19	NULL
4	Dewan Khos	NULL	1	2021-05-09 19:48:19	NULL
5	Majelis Pendekar	NULL	1	2021-05-09 19:48:19	NULL
6	Departemen	NULL	1	2021-05-09 19:48:19	NULL
7	Lembaga Pelatih dan Wasit Juri	NULL	1	2021-05-09 19:48:19	NULL
8	Pusdiklat	NULL	1	2021-05-09 19:48:19	NULL
9	Pasukan Inti (PASTI)	NULL	1	2021-05-09 19:48:19	NULL
10	Ketua Umum	NULL	1	2021-05-09 19:48:19	NULL

=== TABLE: roles ===
id	name	is_deleted	is_locked	created	updated
1	Superadmin	0	0	2023-04-04 17:16:08	NULL
2	Verifikator	0	0	2023-04-04 17:16:08	NULL
3	Observer	0	0	2023-04-04 17:16:08	NULL
4	Publik	0	0	2023-04-04 17:16:08	NULL

=== TABLE: permission ===

=== TABLE: roles_permission ===

=== TABLE: roles_menu ===
Id	IdRoles	JsonMenu
5	1	{"compact":[{"id":"example","title":"Example","type":"basic","icon":"heroicons_outline:chart-pie","link":"/example"}],"default":[{"id":"dashboard","title":"Dashboard","type":"basic","icon":"heroicons_outline:chart-pie","link":"/dashboard"},{"id":"daftar-anggota","title":"Daftar Anggota","type":"basic","icon":"heroicons_outline:user-group","link":"/daftar-anggota"},{"id":"manajemen-akun","title":"Manajemen Akun","type":"basic","icon":"heroicons_outline:users","link":"/manajemen-akun"},{"id":"manajemen-wilayah","title":"Manajemen Wilayah","type":"basic","icon":"heroicons_outline:map","link":"/manajemen-wilayah"},{"id":"manajemen-kepengurusan","title":"Manajemen Kepengurusan","type":"basic","icon":"heroicons_outline:map","link":"/manajemen-kepengurusan"}],"futuristic":[{"id":"example","title":"Example","type":"basic","icon":"heroicons_outline:chart-pie","link":"/example"}],"horizontal":[{"id":"example","title":"Example","type":"basic","icon":"heroicons_outline:chart-pie","link":"/example"}]}
6	2	{"compact":[{"id":"example","title":"Example","type":"basic","icon":"heroicons_outline:chart-pie","link":"/example"}],"default":[{"id":"dashboard","title":"Dashboard","type":"basic","icon":"heroicons_outline:chart-pie","link":"/dashboard"},{"id":"daftar-anggota","title":"Daftar Anggota","type":"basic","icon":"heroicons_outline:user-group","link":"/daftar-anggota"}],"futuristic":[{"id":"example","title":"Example","type":"basic","icon":"heroicons_outline:chart-pie","link":"/example"}],"horizontal":[{"id":"example","title":"Example","type":"basic","icon":"heroicons_outline:chart-pie","link":"/example"}]}
7	3	{"compact":[{"id":"example","title":"Example","type":"basic","icon":"heroicons_outline:chart-pie","link":"/example"}],"default":[{"id":"dashboard","title":"Dashboard","type":"basic","icon":"heroicons_outline:chart-pie","link":"/dashboard"},{"id":"daftar-anggota","title":"Daftar Anggota","type":"basic","icon":"heroicons_outline:user-group","link":"/daftar-anggota"}],"futuristic":[{"id":"example","title":"Example","type":"basic","icon":"heroicons_outline:chart-pie","link":"/example"}],"horizontal":[{"id":"example","title":"Example","type":"basic","icon":"heroicons_outline:chart-pie","link":"/example"}]}
8	4	{"compact":[{"id":"example","title":"Example","type":"basic","icon":"heroicons_outline:chart-pie","link":"/example"}],"default":[{"id":"example","title":"Example","type":"basic","icon":"heroicons_outline:chart-pie","link":"/example"}],"futuristic":[{"id":"example","title":"Example","type":"basic","icon":"heroicons_outline:chart-pie","link":"/example"}],"horizontal":[{"id":"example","title":"Example","type":"basic","icon":"heroicons_outline:chart-pie","link":"/example"}]}

=== TABLE: pribadi ===
idpribadi	publicid	nama	tempat_lahir	tgl_lahir	kelamin	gol_darah	agama	stat_kawin	is_wni	is_pelatih	is_pengurus	is_verified	is_admin	jabatan_pn	verified_date	nokta	nohp	is_email_first_login	IdKelurahanKtp	IdKabupatenDomisili	IdKelurahanDomisili	KabupatenKtp	KabupatenDomisili	created	updated	json_alamat	json_pendidikan	json_pekerjaan	json_perguruan	verifier	url_ktp	url_foto	scopedata
1	ba0857e271669	Malik, S.Pd	Surabaya	1979-09-21 00:00:00	p	b	islam	NULL	1	0	1	1	0	PASTI Pimpinan Pusat	2019-01-30 23:30:16	86163808000001	082139709745	1	40382	264	40382	NULL	3578	2019-01-24 17:20:43	2024-11-16 23:50:51	{"jalan": "Rejosari Pesantren IV no 14", "rtrw": "008 003"}	{"pendidikan_terakhir": "-", "pondok": {"nama_pondok": "-", "pengasuh": "-", "alamat_pondok": "-", "telp_pondok": "-"}, "sekolah": {"nama_sekolah": "-", "alamat_sekolah": "-", "telp_sekolah": "-"}}	{"pekerjaan": "Pegawai Swasta"}	{"nama": "Pagar Nusa", "pengasuh": "M Zainal Suwari", "alamat": "Jl Masjid Al Akbar Timur no 9 Surabaya", "telp": "-", "pelatih": "-", "lokasilatihan": "-"}	1	id/3578/3578281_20190830_142914_P5F_3578302109790001.jpeg	pic/3578/3578281_20190830_142914_YhK_3578302109790001.jpg	3578301005
2	146c401750136	Mohammad Sholihudin S.Sn	Pacitan	1970-01-01 00:00:00	p	ab	islam	NULL	1	0	1	1	0	Majelis Pendekar Pimpinan Pusat	2019-08-19 19:22:25	86150108000001	085820438399	1	33634	224	33634	NULL	3402	2019-01-24 17:25:53	2024-11-16 23:50:51	{"jalan": "Tingas Cepoko", "rtrw": "RT 06"}	{"pendidikan_terakhir": "-", "pondok": {"nama_pondok": "-", "pengasuh": "-", "alamat_pondok": "-", "telp_pondok": "-"}, "sekolah": {"nama_sekolah": "-", "alamat_sekolah": "-", "telp_sekolah": "-"}}	{"pekerjaan": "Pegawai Swasta"}	{"nama": "PS Pagar Nusa", "pengasuh": "Mohammad Sholihudin", "alamat": "-", "telp": "-", "pelatih": "-", "lokasilatihan": "-"}	548804bf48ca73cb2ee6ae2b535221e2	id/2019-01-24_17-25-53_oAs_3402050911680002.jpg	pic/3402/3402050_20200620_152818_eVC_3402050911680002.jpg	NULL
3	92a749c2ea662	Syahrul Anwar	Kabupaten-Tangerang	1996-01-13 00:00:00	p		islam	NULL	1	0	1	1	0	Sekretaris Pimpinan Anak Cabang Sepatan Timur - Kabupaten Tangerang	2020-04-21 10:58:33	86110408000065	089505103562	1	41189	268	41189	NULL	3603	2019-01-24 17:49:06	2024-11-16 23:50:51	{"jalan": "Kp Utan Jati", "rtrw": "003 001"}	{"pendidikan_terakhir": "-", "pondok": {"nama_pondok": "-", "pengasuh": "-", "alamat_pondok": "-", "telp_pondok": "-"}, "sekolah": {"nama_sekolah": "-", "alamat_sekolah": "-", "telp_sekolah": "-"}}	{"pekerjaan": "Pelajar"}	{"nama": "PSNU Pagar Nusa", "pengasuh": "-", "alamat": "-", "telp": "-", "pelatih": "Ahmad Syamsuri", "lokasilatihan": "Sepatan"}	9cb498d747db46cb397565832d41d064	id/2019-01-24_17-49-06_Upa_3603301302960002.jpg	pic/3603/3603181_20200423_164814_Taj_3603301302960002.jpg	NULL
4	c0b9e6a9ff63d	MOHAMMAD SAEFI	PASURUAN	1983-12-07 00:00:00	p		islam	NULL	1	0	0	1	0	Anggota - PC Kabupaten Pasuruan	2019-08-18 05:45:52	86162008000002	085715515250	1	36485	241	36485	NULL	3514	2019-01-24 17:52:13	2024-11-16 23:50:51	{"jalan": "Jalan raya beromo no 06", "rtrw": "021 008"}	{"pondok": {"nama_pondok": "", "pengasuh": "", "alamat_pondok": "", "telp_pondok": ""}, "sekolah": {"nama_sekolah": "", "alamat_sekolah": "", "telp_sekolah": ""}}	{"pekerjaan": "Pegawai Swasta"}	{"nama": "Perguruan pagar nusa", "pengasuh": "M ZAINAL SUWARI", "alamat": "Jl masjid alakbar timur no 9 surabaya", "telp": "", "pelatih": "-", "lokasilatihan": "-"}	548804bf48ca73cb2ee6ae2b535221e2	id/3514/3514060_20190818_054543_7ns_3514161207830001.jpeg	pic/3514/3514060_20200603_152702_DpO_3514161207830001.jpg	3514
5	a42be84efa22e	Badru salam	Tangerang	1997-01-06 00:00:00	p		islam	NULL	1	0	1	1	0	Ketua Pengurus Harian Pimpinan Anak Cabang Sepatan Timur - Kabupaten Tangerang	2020-04-21 10:57:19	86110408000064	081211274895	1	41187	268	41187	NULL	3603	2019-01-24 17:52:16	2024-11-16 23:50:51	{"jalan": "Kp bayur opak", "rtrw": "006 005"}	{"pendidikan_terakhir": "-", "pondok": {"nama_pondok": "-", "pengasuh": "-", "alamat_pondok": "-", "telp_pondok": "-"}, "sekolah": {"nama_sekolah": "-", "alamat_sekolah": "-", "telp_sekolah": "-"}}	{"pekerjaan": "Pelajar"}	{"nama": "PAGAR NUSA", "pengasuh": "-", "alamat": "-", "telp": "-", "pelatih": "Ahmad Syamsuri", "lokasilatihan": "Sepatan"}	9cb498d747db46cb397565832d41d064	id/3603/3603181_20200421_105655_B62_3671080601970002.jpg	pic/3603/3603181_20200421_105655_9Pr_3671080601970002.jpg	NULL
7	ed5940e6d9280	MUCHTARUDDIN	Pacitan	1971-06-18 00:00:00	p		islam	NULL	1	0	1	1	0	Wakil Ketua Umum Pimpinan Pusat	2019-08-18 05:33:46	86230808000001	081253211441	1	51749	363	51749	NULL	6471	2019-01-24 18:21:04	2025-12-10 20:03:34	{"jalan": "Jalan brantas 9 no 139", "rtrw": "036"}	{"pondok": {"nama_pondok": "", "pengasuh": "", "alamat_pondok": "", "telp_pondok": ""}, "sekolah": {"nama_sekolah": "", "alamat_sekolah": "", "telp_sekolah": ""}}	{"pekerjaan": "Lainnya"}	{"lokasilatihan":"-","pelatih":"-","nama":"Pagar Nusa","alamat":"Jalan brantas 9 no 039 rt 036 kelurahan batu ampar kecamatan balikpapan utara kota balikpapan","pengasuh":"-","telp":"-"}	548804bf48ca73cb2ee6ae2b535221e2	id/2019-01-24_18-21-04_U4d_6471031801710001.jpg	pic/6471/6471030_20190816_195541_Ass_6471031801710001.jpg	6471
8	031e40e3c40dc	Suherman	Serang	2019-01-26 00:00:00	p	b	islam	NULL	1	0	1	1	0	Pasti Pimpinan Cabang Kota Serang	2020-01-15 00:20:42	86110608000003	081906296330	1	41636	272	41636	NULL	3673	2019-01-26 19:49:28	2024-11-16 23:50:51	{"jalan": "Link tembong indah", "rtrw": "002 001"}	{"pendidikan_terakhir": "-", "pondok": {"nama_pondok": "Ponpes al fathaniyah", "pengasuh": "Pengurus", "alamat_pondok": "Tembong indah cipocok", "telp_pondok": "081906072005"}, "sekolah": {"nama_sekolah": "Al fathaniyah", "alamat_sekolah": "Tembong indah cipocok jaya kota serang", "telp_sekolah": "081906072005"}}	{"pekerjaan": "Guru", "organisasi_0": {"nama": "Pengurus pondok", "jabatan": "Ketua"}, "jml_organisasi": 1}	{"nama": "Bandrong", "pengasuh": "Anggota", "alamat": "Cilegon merak", "telp": " ", "pelatih": "-", "lokasilatihan": "-"}	548804bf48ca73cb2ee6ae2b535221e2	id/3673/3673030_20200115_003441_O5I_3672060306860002.jpeg	pic/3673/3673030_20200115_003558_l77_3672060306860002.jpeg	NULL
9	e42c99437aece	ALI MUNASHIKIN	NGANJUK	1976-06-01 00:00:00	p		islam	NULL	1	0	1	1	0	Wakil Sekretaris Pimpinan Wilayah Bali	2019-01-29 16:25:27	86170908000001	081337561061	0	74818	282	74818	NULL	5171	2019-01-29 10:03:18	2024-11-16 23:50:51	{"jalan": "Jalan Perum Padang Galeria No 1", "rtrw": "-"}	{"pondok": {"nama_pondok": "", "pengasuh": "", "alamat_pondok": "", "telp_pondok": ""}, "sekolah": {"nama_sekolah": "SMA", "alamat_sekolah": "Jalan Raya Kediri Pace Nganjuk", "telp_sekolah": ""}}	{"pekerjaan": "Pegawai Swasta", "organisasi_0": {"nama": "PSNU Pagar Nusa", "jabatan": "Wakil Sekretaris"}, "organisasi_1": {"nama": " LPBI NU Bali", "jabatan": " Relawan Inti"}, "jml_organisasi": 2}	{"nama": "Pencak Silat NU Pagar Nusa Provinsi Bali PW Pagar Nusa Bali", "pengasuh": "Drs H Zaimuri S Pd I", "alamat": "Gedung Serbaguna PWNU Prov Bali Jalan Pura Demak No 32 Banjar Buagan Pemecutan Kelod Denpasar Barat 80119 Bali", "telp": "", "pelatih": "-", "lokasilatihan": "-"}	1	id/2019-01-29_10-03-18_5BQ_3518050106760004.jpg	pic/5171/5171030_20200711_005403_OA3_3518050106760004.jpg	51
10	306905851184d	KATIMAN AGUS SUPRIANTO	BOJONEGORO	1983-08-09 00:00:00	p	b	islam	NULL	1	0	1	1	0	Ketua Pimpinan Wilayah Kalimantan Selatan	2024-07-07 20:43:34	86211208000001	085106355536	1	50935	355	50935	NULL	6372	2019-01-30 16:27:41	2024-11-16 23:50:51	{"jalan": "JL SUKAMARA GANG V", "rtrw": "001 002"}	{"pondok": {"nama_pondok": "", "pengasuh": "", "alamat_pondok": "", "telp_pondok": ""}, "sekolah": {"nama_sekolah": "", "alamat_sekolah": "", "telp_sekolah": ""}}	{"pekerjaan": "Wiraswasta", "organisasi_0": {"nama": "BANSER", "jabatan": "KASAT PROVOST WILAYAH"}, "jml_organisasi": 1}	{"nama": "GASMI", "pengasuh": "ABDUL LATIF", "alamat": "KEDIRI", "telp": "", "pelatih": "-", "lokasilatihan": "-"}	7b03e6a75d177	id/6372/6372011_20210905_175003_PBe_6371020809830004.jpg	pic/6372/6372011_20210905_175003_Rnj_6371020809830004.jpg	6372
11	2f200b8465444	Abdullatif	Batang	1985-09-09 00:00:00	p	ab	islam	NULL	1	0	1	1	0	Pasukan Inti (PASTI) Pimpinan Cabang Kabupaten Wonosobo	2023-08-02 23:19:06	86142908000001	085328773779	1	28003	194	28003	NULL	3307	2019-01-31 19:32:07	2024-11-16 23:50:51	{"jalan": "Jalan Jend Suharto KM 6 Campursari Selomerto", "rtrw": "001 001"}	{"pendidikan_terakhir": "sma", "pondok": {"nama_pondok": "KYAI PARAK BAMBU RUNCING", "pengasuh": "KH KHAEDAR MUHAIMINAN GUNARDHO", "alamat_pondok": "COYUDAN PARAKAN", "telp_pondok": "-"}, "sekolah": {"nama_sekolah": "SUPM SMK NUSANTARA", "alamat_sekolah": "kARANGASEM BATANG", "telp_sekolah": "-"}}	{"pekerjaan": "Wiraswasta", "organisasi_0": {"nama": "IPNU", "jabatan": "-"}, "organisasi_1": {"nama": " ANSOR", "jabatan": "-"}, "jml_organisasi": 2}	{"nama": "Pagar Nusa", "pengasuh": "Abah Harun Heru S", "alamat": "Sojomerto Reban batang", "telp": "-", "pelatih": "-", "lokasilatihan": "-"}	38f0965f6e0df	id/2019-01-31_19-32-07_sM7_3307060909850007.jpg	pic/2019-01-31_19-32-07_LOv_3307060909850007.jpg	3307

=== TABLE: user ===
iduser	idpribadi	username	fullname	email	isactive	lastlogin	created	updated
1	4	saefimohammad5	MOHAMMAD SAEFI	saefimohammad5@gmail.com	1	NULL	2023-04-30 19:36:14	2023-06-11 15:49:44
2	7	mohtaruddin507	Muchtaruddin	mohtaruddin507@gmail.com	1	NULL	2023-04-30 20:23:37	2023-06-11 15:49:44
3	9	alia6521	ALI MUNASHIKIN	alia6521@gmail.com	1	2026-04-16 10:38:52	2023-04-30 20:23:37	2026-04-16 10:38:52
4	10	bagusbungas58	KATIMAN AGUS SUPRIANTO	bagusbungas58@gmail.com	1	NULL	2023-04-30 20:23:37	2023-06-11 15:49:44
5	11	chreeptoss	Abdullatif	chreeptoss@gmail.com	1	NULL	2023-04-30 20:23:37	2023-06-11 15:49:44
6	12	iping2302	Pingki Ans Saputra	iping2302@gmail.com	1	NULL	2023-04-30 20:23:37	2023-06-11 15:49:44
7	13	1471090104750022	M.Sulaiman Basyir	msulaimanbasyir@gmail.com 	1	2026-01-25 09:59:17	2023-04-30 20:23:37	2026-01-25 09:59:16
8	15	nurridwan87	Nur Ridwan	nurridwan87@gmail.com	1	2023-12-26 13:51:56	2023-04-30 20:23:37	2023-12-26 13:51:56
9	25	emisumirta207	Emi sumirta. SE. MSi	emisumirta207@gmail.com	1	NULL	2023-04-30 20:23:37	2023-06-11 15:49:44
10	32	pagarnusajateng1	Heru Supriyanto	pagarnusajateng1@gmail.com	1	NULL	2023-04-30 20:23:37	2023-06-11 15:49:44

=== TABLE: user_roles ===
iduserroles	iduser	idroles	created
1	1	4	2023-04-30 20:36:54
2	2	4	2023-04-30 20:36:54
3	3	2	2023-04-30 20:36:54
4	4	4	2023-04-30 20:36:54
5	5	4	2023-04-30 20:36:54
6	6	4	2023-04-30 20:36:54
7	7	2	2023-04-30 20:36:54
8	8	4	2023-04-30 20:36:54
9	9	4	2023-04-30 20:36:54
10	10	4	2023-04-30 20:36:54

=== TABLE: penomoran ===
IdPenomoran	IdPribadi	IdProv	IdKota	NoUrut	KodeKotaPn	NoKta	Created	Updated
1	92664	1	19	1	0119	86011908000001	2023-04-30 21:25:14	NULL
3	107460	2	30	2	0204	86020408000002	2023-04-30 21:25:14	NULL
4	107274	2	30	3	0204	86020408000003	2023-04-30 21:25:14	NULL
5	107272	2	30	4	0204	86020408000004	2023-04-30 21:25:14	NULL
6	110681	2	44	1	0216	86021608000001	2023-04-30 21:25:14	NULL
7	110683	2	44	2	0216	86021608000002	2023-04-30 21:25:14	NULL
8	87901	2	44	3	0216	86021608000003	2023-04-30 21:25:14	NULL
11	122184	2	44	6	0216	86021608000006	2023-04-30 21:25:14	NULL
12	110716	2	43	1	0217	86021708000001	2023-04-30 21:25:14	NULL
13	117725	2	26	12	0222	86022206000012	2023-04-30 21:25:14	NULL

=== TABLE: kepengurusan ===
id_kepengurusan	level_id	nama_kepengurusan	kode_wilayah	periode_mulai	periode_selesai	is_active	is_pengurus	json_kepengurusan	url_file	OldKodeWilayah	IdWilayah	created	updated
1	3	Pimpinan Cabang Kota Jayapura	9171	NULL	NULL	1	0	NULL	NULL	9471	501	2023-04-28 21:26:40	2023-04-28 21:44:44
2	3	Pimpinan Cabang Kabupaten Waropen	9115	NULL	NULL	1	0	NULL	NULL	9426	487	2023-04-28 21:26:40	2023-04-28 21:44:44
3	3	Pimpinan Cabang Kabupaten Boven Digoel	9116	NULL	NULL	1	0	NULL	NULL	9413	488	2023-04-28 21:26:40	2023-04-28 21:44:44
4	3	Pimpinan Cabang Kabupaten Biak Numfor	9106	NULL	NULL	1	0	NULL	NULL	9409	478	2023-04-28 21:26:40	2023-04-28 21:44:44
5	3	Pimpinan Cabang Kabupaten Nabire	9104	NULL	NULL	1	0	NULL	NULL	9404	476	2023-04-28 21:26:40	2023-04-28 21:44:44
6	3	Pimpinan Cabang Kabupaten Jayapura	9103	NULL	NULL	1	0	NULL	NULL	9403	475	2023-04-28 21:26:40	2023-04-28 21:44:44
7	3	Pimpinan Cabang Kota Sorong	9271	NULL	NULL	1	0	NULL	NULL	9171	514	2023-04-28 21:26:40	2023-04-28 21:44:44
8	3	Pimpinan Cabang Kabupaten Manokwari Selatan	9211	NULL	NULL	1	0	NULL	NULL	9111	512	2023-04-28 21:26:40	2023-04-28 21:44:44
9	3	Pimpinan Cabang Kabupaten Sorong	9201	NULL	NULL	1	0	NULL	NULL	9107	502	2023-04-28 21:26:40	2023-06-27 08:15:27
10	3	Pimpinan Cabang Kabupaten Manokwari	9202	NULL	NULL	1	0	NULL	NULL	9105	503	2023-04-28 21:26:40	2023-04-28 21:44:44

=== TABLE: detil_kepengurusan ===
id_detil_kepengurusan	kepengurusan_id	kode_wilayah	pribadi_id	jabatan_id	jabatan_pn	is_active	OldKodeWilayah	IdWilayah	created	updated
1	1367	3171	1	9	Pasukan Inti (PASTI)	1	NULL	NULL	2023-04-30 18:47:00	NULL
2	1367	3171	2	5	Majelis Pendekar	1	NULL	NULL	2023-04-30 18:47:00	NULL
3	1367	3171	300	1	Anggota	1	NULL	NULL	2023-04-30 18:47:00	NULL
6	1367	3171	316	9	Pasukan Inti (PASTI)	1	NULL	NULL	2023-04-30 18:47:00	NULL
7	1367	3171	333	9	Pasukan Inti (PASTI)	1	NULL	NULL	2023-04-30 18:47:00	NULL
8	1367	3171	334	9	Pasukan Inti (PASTI)	1	NULL	NULL	2023-04-30 18:47:00	NULL
9	1367	3171	344	6	Departemen	1	NULL	NULL	2023-04-30 18:47:00	NULL
10	1367	3171	354	9	Pasukan Inti (PASTI)	1	NULL	NULL	2023-04-30 18:47:00	NULL
11	1367	3171	355	9	Pasukan Inti (PASTI)	1	NULL	NULL	2023-04-30 18:47:00	NULL
12	1367	3171	380	9	Pasukan Inti (PASTI)	1	NULL	NULL	2023-04-30 18:47:00	NULL

=== TABLE: latihan ===

=== TABLE: koneksi_eksternal ===
id	nama	url	isprod	isenabled	pic	created	updated
4	Angular Localhost	http://localhost:4200	0	1	1959df7760d39	2024-06-08 01:25:37	2024-06-26 21:36:32
5	Localhost CI Jawi Toples	http://localhost	0	1	50eb9af3bb30f	2024-07-11 16:14:02	2024-07-11 22:14:18
6	Prod CI Jawi Toples	https://event.jawaraindonesia.co.id	0	1	50eb9af3bb30f	2024-07-11 16:14:02	2024-07-11 22:14:08

=== TABLE: temp_updatefoto ===
idpribadi	url_foto	url_ktp	url_foto_new	url_ktp_new	done_migrasi	done_create_url
1	3578281_20190830_142914_YhK_3578302109790001.jpg	3578281_20190830_142914_P5F_3578302109790001.jpeg	pic/3578/3578281_20190830_142914_YhK_3578302109790001.jpg	id/3578/3578281_20190830_142914_P5F_3578302109790001.jpeg	0	0
2	3402050_20200620_152818_eVC_3402050911680002.jpg	2019-01-24_17-25-53_oAs_3402050911680002.jpg	pic/3402/3402050_20200620_152818_eVC_3402050911680002.jpg	id/2019-01-24_17-25-53_oAs_3402050911680002.jpg	0	0
3	3603181_20200423_164814_Taj_3603301302960002.jpg	2019-01-24_17-49-06_Upa_3603301302960002.jpg	pic/3603/3603181_20200423_164814_Taj_3603301302960002.jpg	id/2019-01-24_17-49-06_Upa_3603301302960002.jpg	0	0
4	3514060_20200603_152702_DpO_3514161207830001.jpg	3514060_20190818_054543_7ns_3514161207830001.jpeg	pic/3514/3514060_20200603_152702_DpO_3514161207830001.jpg	id/3514/3514060_20190818_054543_7ns_3514161207830001.jpeg	0	0
5	3603181_20200421_105655_9Pr_3671080601970002.jpg	3603181_20200421_105655_B62_3671080601970002.jpg	pic/3603/3603181_20200421_105655_9Pr_3671080601970002.jpg	id/3603/3603181_20200421_105655_B62_3671080601970002.jpg	0	0
7	6471030_20190816_195541_Ass_6471031801710001.jpg	2019-01-24_18-21-04_U4d_6471031801710001.jpg	pic/6471/6471030_20190816_195541_Ass_6471031801710001.jpg	id/2019-01-24_18-21-04_U4d_6471031801710001.jpg	0	0
8	3673030_20200115_003558_l77_3672060306860002.jpeg	3673030_20200115_003441_O5I_3672060306860002.jpeg	pic/3673/3673030_20200115_003558_l77_3672060306860002.jpeg	id/3673/3673030_20200115_003441_O5I_3672060306860002.jpeg	0	0
9	5171030_20200711_005403_OA3_3518050106760004.jpg	2019-01-29_10-03-18_5BQ_3518050106760004.jpg	pic/5171/5171030_20200711_005403_OA3_3518050106760004.jpg	id/2019-01-29_10-03-18_5BQ_3518050106760004.jpg	0	0
10	6372011_20210905_175003_Rnj_6371020809830004.jpg	6372011_20210905_175003_PBe_6371020809830004.jpg	pic/6372/6372011_20210905_175003_Rnj_6371020809830004.jpg	id/6372/6372011_20210905_175003_PBe_6371020809830004.jpg	0	0
11	2019-01-31_19-32-07_LOv_3307060909850007.jpg	2019-01-31_19-32-07_sM7_3307060909850007.jpg	pic/2019-01-31_19-32-07_LOv_3307060909850007.jpg	id/2019-01-31_19-32-07_sM7_3307060909850007.jpg	0	0
child_table	child_column	parent_table	parent_column	CONSTRAINT_NAME
detil_kepengurusan	jabatan_id	jabatan	id_jabatan	detil_jabatan_FK
detil_kepengurusan	kepengurusan_id	kepengurusan	id_kepengurusan	detil_kepengurusan_FK
detil_kepengurusan	pribadi_id	pribadi	idpribadi	detil_pribadi_FK
jabatan	level_id	level	id_level	jabatan_level_FK
kabupaten	idParent	provinsi	id	kabupaten_prov_FK
kecamatan	idParent	kabupaten	id	kecamatan_kabupaten_FK
kelurahan	idParent	kecamatan	id	kelurahan_kecamatan_FK
kepengurusan	level_id	level	id_level	kepengurusan_level_FK
latihan	kecamatan_id	kecamatan	id	latihan_kecamatan_FK
latihan	padepokan_id	padepokan	id_padepokan	latihan_padepokan_FK
latihan	pelatih_id	pribadi	idpribadi	latihan_pribadi_FK
penomoran	IdKota	kabupaten	id	penomoran_kota_FK
penomoran	IdPribadi	pribadi	idpribadi	penomoran_pribadi_FK
penomoran	IdProv	provinsi	id	penomoran_provinsi_FK
roles_permission	permission_id	permission	id	fk_permission_group2
roles_permission	roles_id	roles	id	fk_group2
TABLE_NAME	estimated_rows	data_mb	TABLE_COMMENT
pribadi	205123	174.73	
penomoran	187772	12.52	
temp_updatefoto	165878	37.56	
user	111521	17.62	
user_roles	111521	1.91	
kepengurusan	86827	10.52	
kelurahan	81181	7.52	diambil dari sini 30 Okt 2021\nhttps://github.com/cahyadsn/wilayah
detil_kepengurusan	22612	1.52	
kecamatan	7137	1.52	diambil dari sini 30 Okt 2021\nhttps://github.com/cahyadsn/wilayah
kabupaten	527	0.08	diambil dari sini 30 Okt 2021\nhttps://github.com/cahyadsn/wilayah
jabatan	135	0.02	
provinsi	35	0.02	diambil dari sini 30 Okt 2021\nhttps://github.com/cahyadsn/wilayah
level	6	0.02	
roles	4	0.02	
roles_menu	4	0.02	
koneksi_eksternal	3	0.02	table untuk simpan koneksi eksternal ke backend services
latihan	0	0.02	tabel lokasi latihan ini
padepokan	0	0.02	
permission	0	0.02	
roles_permission	0	0.02	
