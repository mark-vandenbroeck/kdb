drop table kdb_tkt_bestellings_lijnen;
create table kdb_tkt_bestellings_lijnen
(
	ID 										NUMBER(10,0), 
	CREATED_DT 						DATE, 
	MODIFIED_DT			 			DATE, 
	CREATED_BY 						VARCHAR2(60 CHAR), 
	MODIFIED_BY						VARCHAR2(60 CHAR), 
	VERSION_NO 						NUMBER(10,0),
	tkt_evenement_id			number							not null,
	tkt_voorstellings_id	number							not null,
	tkt_categorie_id			number							not null,
	aantal								number							not null,
	--
	constraint kdb_tkt_best_lijnen_pk        primary key (id),
	constraint kdb_tkt_best_lijnen_fk_evt    foreign key (tkt_evenement_id)     references kdb_tkt_evenements(id),
	constraint kdb_tkt_best_lijnen_fk_voorst foreign key (tkt_evenement_id)     references kdb_tkt_voorstellings(id),
	constraint kdb_tkt_best_lijnen_fk_cat    foreign key (tkt_voorstellings_id) references kdb_tkt_categories(id)
)
;