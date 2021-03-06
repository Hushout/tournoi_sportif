
/*
FIchier : Test_GroupeA.sql
Auteurs : 
Pierre Dupont 2019334455
Paul Dupond 2019335629
Nom du groupe : A
*/

-- drop database if exists BDMASHRACAO;
-- create database BDMASHRACAO;
-- use BDMASHRACAO;

drop table if exists Joue;
drop table if exists Poule;
drop table if exists Terrain;
drop table if exists Tour;
drop table if exists Joueur;
drop table if exists Equipe;
drop table if exists Tournoi;
drop table if exists Evenement;
drop table if exists Sport;
drop table if exists Organisateur;

create table Organisateur(
    Pseudo varchar(50),
    NomOrganisateur varchar(50) not null,
    PrenomOrganisateur varchar(50) not null,
    Mdp varchar(50) not null,
    constraint PK_Organisateur primary key(Pseudo)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

create table Sport(
    TypeJeu varchar(50),
    constraint PK_Sport primary key(TypeJeu)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

create table Evenement(
    IdEvenement int AUTO_INCREMENT,
    NomEvenement varchar(100) not null unique,
    LieuEvenement varchar(100) not null,
    DateEvenement date not null,
    TypeJeu varchar(50) not null,
    NbJoueur numeric(2,0) not null,
    PseudoOrganisateur varchar(50),
    Statue varchar(10) default 'bientot',
    constraint PK_Evenement primary key(IdEvenement),
    constraint FK_Evenement_Organisateur foreign key(PseudoOrganisateur) 
        references Organisateur(Pseudo) on delete set null,
    constraint FK_Evenement_Sport foreign key(TypeJeu) 
        references Sport(TypeJeu) on delete cascade, 
    constraint DOM_Statue_Evenement check(Statue in ('bientot','encours','termine')),
    constraint NbJoueur_positif check(NbJoueur > 0)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

create table Tournoi(
    IdTournoi int AUTO_INCREMENT,
    Categorie varchar(50),
    TypeTournoi varchar(50) default 'principal',
    IdEvenement int not null,
    constraint PK_Tournoi primary key(IdTournoi),
    constraint FK_Tournoi_Evenement foreign key(IdEvenement) 
        references Evenement(IdEvenement) on delete cascade,
    constraint DOM_TypeTournoi_Tournoi check(TypeTournoi in ('principal','consultante')),
    CONSTRAINT UNIQUE_IdEvenement_Categorie_TypeTournoi UNIQUE(IdEvenement,Categorie,TypeTournoi)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;


create table Equipe(
    IdEquipe int AUTO_INCREMENT,
    NomEquipe varchar(50) not null,
    NiveauEquipe numeric(1,0) not null,
    NomClub varchar(50),
    IdTournoi int,
    InscriptionValidee BOOLEAN default false,
    constraint PK_Equipe primary key(IdEquipe),
    constraint FK_Equipe_Tournoi foreign key(IdTournoi) 
        references Tournoi(IdTournoi) on delete cascade,
    CONSTRAINT UNIQUE_NomEquipe_IdTournoi UNIQUE(NomEquipe,IdTournoi),
    constraint DOM_NiveauEquipe check(NiveauEquipe between 1 and 5)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

create table Joueur(
    IdJoueur int AUTO_INCREMENT,
    NomJoueur varchar(50) not null,
    PrenomJoueur varchar(50) not null,
    NiveauJoueur varchar(20) not null,
    IdEquipe int not null,
    constraint PK_Joueur primary key(IdJoueur),
    constraint FK_Joueur_Equipe foreign key(IdEquipe) 
        references Equipe(IdEquipe) on delete cascade, 
    constraint DOM_NiveauJoueur check
        (NiveauJoueur in ('loisir', 'départemental','régional','Elite','Pro'))
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

create table Tour(
    IdTour int AUTO_INCREMENT,
    NomTour varchar(100),
    NumTour int,
    Statue varchar(10) default 'bientot',
    IdTournoi int,
    constraint PK_Tour primary key(IdTour),
    constraint FK_Tour_Tournoi foreign key(IdTournoi)
        references Tournoi(IdTournoi) on delete cascade,
    constraint DOM_Statue_Tour check(Statue in ('bientot','encours','termine')),
    constraint NumTour_positif check(NumTour > 0)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

create table Terrain(
    NumTerrain int AUTO_INCREMENT,
    TypeJeu varchar(50) not null,
    constraint PK_Terrain primary key(NumTerrain),
    constraint FK_Terrain_Sport foreign key(TypeJeu) 
        references Sport(TypeJeu) on delete cascade
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

create table Poule(
    IdPoule int AUTO_INCREMENT,
    NomPoule varchar(100),
    IdTour int,
    NumTerrain int,
    constraint PK_Poule primary key(IdPoule),
    constraint FK_Poule_Tour foreign key(IdTour) 
        references Tour(IdTour) on delete cascade, 
    constraint FK_Poule_Terrain foreign key(NumTerrain) 
        references Terrain(NumTerrain) on delete cascade,
    CONSTRAINT UNIQUE_Poule_NumTerrain UNIQUE(NumTerrain)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;

create table Joue(
    IdPoule int,
    IdEquipe int,
    NbMatch numeric(3,0) default 0,
    NbSet numeric(3,0) default 0,
    NbPoint numeric(3,0) default 0,
    constraint PK_Joue primary key(IdPoule,IdEquipe),
    constraint FK_Joue_Poule foreign key(IdPoule) 
        references Poule(IdPoule) on delete cascade, 
    constraint FK_Joue_Equipe foreign key(IdEquipe) 
        references Equipe(IdEquipe) on delete cascade,
    constraint NbMatch_positif check(NbMatch >= 0),
    constraint NbSet_positif check(NbSet >= 0),
    constraint NbPoint_positif check(NbPoint >= 0)
)ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TRIGGER IF EXISTS Equipe_Inscription_Annulee;
DELIMITER $$
CREATE TRIGGER Equipe_Inscription_Annulee
    AFTER UPDATE ON Evenement
    FOR EACH ROW 
BEGIN    
    IF NEW.Statue = 'encours' THEN
        delete from Equipe where InscriptionValidee=false and IdTournoi in 
            (select IdTournoi from Tournoi where IdEvenement=NEW.IdEvenement);
    END IF;
END $$
DELIMITER ;


DROP TRIGGER IF EXISTS Liberer_Terrain;
DELIMITER $$
CREATE TRIGGER Liberer_Terrain
    AFTER UPDATE ON Tour
    FOR EACH ROW 
BEGIN    
    IF NEW.Statue = 'termine' THEN
        update Poule set NumTerrain=null where IdTour=NEW.IdTour;
    END IF;
END $$
DELIMITER ;


DROP PROCEDURE IF EXISTS Remove_Old_Event;
DELIMITER $$
CREATE PROCEDURE Remove_Old_Event ()
MODIFIES SQL DATA
BEGIN
    DELETE FROM Evenement WHERE Statue='bientot' AND DateEvenement<NOW();
END$$
DELIMITER ;


DROP EVENT IF EXISTS Daily_Remove_Old_Event;
DELIMITER $$
CREATE EVENT Daily_Remove_Old_Event 
ON SCHEDULE EVERY 1 DAY
COMMENT "Suppression quotidienne des anciens événements qui n'ont pas eu lieu" 
DO
BEGIN
    CALL Remove_Old_Event();
END$$
DELIMITER ;


DROP FUNCTION IF EXISTS Get_Classement;
DELIMITER $$
CREATE FUNCTION Get_Classement (idE INT)
RETURNS NUMERIC(3,0)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE finished INTEGER DEFAULT 0;
    DECLARE cpt NUMERIC(3,0) DEFAULT 1;
    DECLARE var_idE INT;
    DECLARE IdEquipe_cursor CURSOR FOR SELECT E.IdEquipe FROM Tournoi Tn JOIN Tour Tr ON Tr.IdTournoi=Tn.IdTournoi 
        JOIN Poule P ON P.IdTour=Tr.IdTour JOIN Joue J ON J.IdPoule=P.IdPoule JOIN Equipe E ON E.IdEquipe=J.IdEquipe WHERE 
        E.IdTournoi=(SELECT IdTournoi FROM Equipe E2 WHERE E2.IdEquipe=idE) and E.InscriptionValidee=true 
        GROUP BY E.IdEquipe ORDER BY sum(NbMatch) DESC,sum(NbSet) DESC,sum(NbPoint) DESC;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1;
    OPEN IdEquipe_cursor;
    equipe_loop: LOOP
        FETCH IdEquipe_cursor INTO var_idE; 
        IF finished = 1 or var_idE=idE THEN 
			LEAVE equipe_loop;
		END IF;
        SET cpt=cpt+1; 
    END LOOP;
    CLOSE IdEquipe_cursor;
    RETURN (cpt);
END$$
DELIMITER ;

-- select Get_Classement(IdEquipe) from Equipe;
-- DECLARE Classement NUMERIC(3,0);
    -- DECLARE nbJoue NUMERIC(3,0);
    -- DECLARE nbM NUMERIC(3,0);
    -- DECLARE nbS NUMERIC(3,0);
    -- DECLARE nbP NUMERIC(3,0);
    -- SELECT count(*) INTO nbJoue,NbMatch INTO nbM,NbSet INTO nbS,NbPoint INTO nbP FROM Joue WHERE IdEquipe=idE;
    -- IF nbJoue = 0 THEN  
    --     SET Classement = NULL;
    -- ELSE 
    --     SELECT count(*)+1 INTO Classement FROM Equipe WHERE IdTournoi=(SELECT IdTournoi FROM Equipe WHERE IdEquipe=idE)
    --         AND ;
    -- END IF;
-- DELIMITER $$
-- CREATE TRIGGER Equipe_Inscription_Annulee
--     AFTER UPDATE ON Evenement
--     FOR EACH ROW 
-- BEGIN    
--     DECLARE idE int;
--     DECLARE IdEquipe_cursor CURSOR FOR SELECT IdEquipe FROM Equipe where InscriptionValidee=false;
--     IF NEW.Statue = 'encours' THEN
--         OPEN IdEquipe_cursor;
--         equipe_loop: LOOP
--             FETCH IdEquipe_cursor INTO idE; 
--             delete from Equipe where IdEquipe=idE;
--         END LOOP;
--         CLOSE IdEquipe_cursor;
--     END IF;
-- END $$
-- DELIMITER ;


-- DELIMITER $$
-- CREATE TRIGGER Equipe_Inscription_Annulee
--     AFTER UPDATE ON Evenement
--     FOR EACH ROW 
-- BEGIN    

--     IF NEW.Statue = 'encours' THEN
--         delete from Equipe where InscriptionValidee=false and IdTournoi in 
--             (select IdTournoi from Tournoi where IdEvenement=NEW.IdEvenement);
--     END IF;
-- END $$
-- DELIMITER ;

-- DECLARE IdEquipe_cursor CURSOR FOR SELECT IdEquipe FROM Equipe where InscriptionValidee=false and IdTournoi in 
--         (SELECT IdTournoi from Tournoi where IdEvenement=NEW.Statue);
    
--     IF NEW.Statue = 'encours' THEN
--         #SET MESSAGE_ERROR=CONCAT()
--         INSERT INTO LOGERROR(MESSAGE) VALUES ("ERREUR AVION DANS VILLE DIFFERENTE");
--         SIGNAL SQLSTATE VALUE '45000' SET MESSAGE_TEXT ="LES VOLS DOIVENT UTILISER DES AVIONS LOCALISES DANS LA MEME VILLE QUE LA VILLE DE DEPART";
--     END IF;

/* 
Trigger pour garantir qu'un salaire est supérieur à 0
*/



-- DROP TRIGGER IF EXISTS ATTENTION_SALAIRE
-- DELIMITER $$
-- CREATE TRIGGER ATTENTION_SALAIRE
-- BEFORE INSERT on pilote
-- FOR EACH ROW BEGIN 
-- IF NEW.SAL=0 THEN
--     INSERT INTO LOGERROR(MESSAGE) VALUES (CONCAT("ATTENTION, LE SALAIRE DOIT ETRE SUPERIEUR A 0"));
--     SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'LE SALAIRE DOIT ËTRE SUPERIEUR A 0';
-- END IF; 
-- END; $$



-- INSERTION Organisateur

-- INSERT INTO Organisateur VALUES('sangri','mashra','marwan',SHA1('123456'));
-- Insert into Organisateur values('Sokz','DOMY','Andre',SHA1('123'));
-- Insert into Organisateur values ('MaradonaGod','Balder','Darius',SHA1('Dadababa1'));
-- Insert into Organisateur values ('Gunnix','Hereinstein','Sophie',SHA1('chopinnocturne20'));
-- Insert into Organisateur values ('BlackMamba','Bryant','Kobe',SHA1('Lakers4ever'));

-- INSERTION Sport

-- Insert into Sport values ('Football');
-- Insert into Sport values ('Basket-ball');

-- INSERTION Evenement

-- Insert into Evenement values (null,'Tournois2','Londre','2020-12-09','Football',3,'MaradonaGod','encours');
-- Insert into Evenement values (null,'SeriesTournois3','Nice','2021-12-10','Basket-ball',3,'BlackMamba','bientot');

-- INSERTION TournoiS

-- Insert into Tournoi values (null,'Adulte','principal',1);
-- Insert into Tournoi values (null,'Adulte','principal',2);
-- Insert into Tournoi values (null,'Femme','principal',1);
-- Insert into Tournoi values (null,'Femme','principal',2);

-- INSERTION Equipe


-- Insert into Equipe values(null,'PSG1',4,'Paris-St-Germain',1,true);
-- Insert into Equipe values(null,'OM1',2,'Olympique-de-Marseille',1,true);
-- Insert into Equipe values(null,'OL1',2,'Olympique-Lyonnais',1,true);
-- Insert into Equipe values(null,'REAL1',1,'Real Madrid',1,true);

-- Insert into Equipe values(null,'PSG2',4,'Paris-St-Germain',1,true);
-- Insert into Equipe values(null,'OM2',2,'Olympique-de-Marseille',1,true);
-- Insert into Equipe values(null,'OL2',2,'Olympique-Lyonnais',1,true);


-- Insert into Equipe values(null,'PSG1',4,'Paris-St-Germain',1,true);
-- Insert into Equipe values(null,'OM1',2,'Olympique-de-Marseille',1,true);
-- Insert into Equipe values(null,'OL1',2,'Olympique-Lyonnais',1,true);
-- Insert into Equipe values(null,'REAL1',1,'Real Madrid',1,true);

-- Insert into Equipe values(null,'PSG2',4,'Paris-St-Germain',1,true);
-- Insert into Equipe values(null,'OM2',2,'Olympique-de-Marseille',1,true);
-- Insert into Equipe values(null,'OL2',2,'Olympique-Lyonnais',1,true);
-- Insert into Equipe values(null,'REAL2',1,'Real Madrid',1,true);

-- Insert into Equipe values(null,'PSG3',4,'Paris-St-Germain',1,true);
-- Insert into Equipe values(null,'OM3',2,'Olympique-de-Marseille',1,true);
-- Insert into Equipe values(null,'OL3',2,'Olympique-Lyonnais',1,true);
-- Insert into Equipe values(null,'REAL3',1,'Real Madrid',1,true);

-- Insert into Equipe values(null,'PSG4',4,'Paris-St-Germain',1,true);
-- Insert into Equipe values(null,'OM4',2,'Olympique-de-Marseille',1,true);
-- Insert into Equipe values(null,'OL4',2,'Olympique-Lyonnais',1,true);
-- Insert into Equipe values(null,'REAL4',1,'Real Madrid',1,true);

-- Insert into Equipe values(null,'KangooJnr',5,null,2,false);
-- Insert into Equipe values(null,'TortueNinja',5,null,2,false);

-- INSERTION Joueur

-- INSERT into Joueur values(null,'Neymar','da Silva Santos Júnior','Pro',1);
-- INSERT into Joueur values(null,'Mbappé','Kylian','Pro',1);
-- INSERT into Joueur values(null,'Köpke','Andreas','Pro',1);
-- INSERT into Joueur values(null,'Zinedine','Zidane','Pro',2);
-- INSERT into Joueur values(null,'Barthez','Fabien','Pro',2);
-- INSERT into Joueur values(null,'Waddle','Chris','Pro',2);
-- INSERT into Joueur values(null,'Pernambucano','Juninho','Pro',3);
-- INSERT into Joueur values(null,'Gomez','Yohan','Pro',3);
-- INSERT into Joueur values(null,'Hartock','Joan','Pro',3);
-- INSERT into Joueur values(null,'Vieira','Marcelo','Pro',4);
-- INSERT into Joueur values(null,'Lunin','Andriy','Pro',4);
-- INSERT into Joueur values(null,'Modric','Luka','Pro',4);

-- INSERT into Joueur values(null,'Neymar','da Silva Santos Júnior','Pro',5);
-- INSERT into Joueur values(null,'Mbappé','Kylian','Pro',5);
-- INSERT into Joueur values(null,'Köpke','Andreas','Pro',5);
-- INSERT into Joueur values(null,'Zinedine','Zidane','Pro',6);
-- INSERT into Joueur values(null,'Barthez','Fabien','Pro',6);
-- INSERT into Joueur values(null,'Waddle','Chris','Pro',6);
-- INSERT into Joueur values(null,'Pernambucano','Juninho','Pro',7);
-- INSERT into Joueur values(null,'Gomez','Yohan','Pro',7);
-- INSERT into Joueur values(null,'Hartock','Joan','Pro',7);


-- INSERT into Joueur values(null,'Vieira','Marcelo','Pro',8);
-- INSERT into Joueur values(null,'Lunin','Andriy','Pro',8);
-- INSERT into Joueur values(null,'Modric','Luka','Pro',8);

-- INSERT into Joueur values(null,'Neymar','da Silva Santos Júnior','Pro',9);
-- INSERT into Joueur values(null,'Mbappé','Kylian','Pro',9);
-- INSERT into Joueur values(null,'Köpke','Andreas','Pro',9);
-- INSERT into Joueur values(null,'Zinedine','Zidane','Pro',10);
-- INSERT into Joueur values(null,'Barthez','Fabien','Pro',10);
-- INSERT into Joueur values(null,'Waddle','Chris','Pro',10);
-- INSERT into Joueur values(null,'Pernambucano','Juninho','Pro',11);
-- INSERT into Joueur values(null,'Gomez','Yohan','Pro',11);
-- INSERT into Joueur values(null,'Hartock','Joan','Pro',11);
-- INSERT into Joueur values(null,'Vieira','Marcelo','Pro',12);
-- INSERT into Joueur values(null,'Lunin','Andriy','Pro',12);
-- INSERT into Joueur values(null,'Modric','Luka','Pro',12);

-- INSERT into Joueur values(null,'Neymar','da Silva Santos Júnior','Pro',13);
-- INSERT into Joueur values(null,'Mbappé','Kylian','Pro',13);
-- INSERT into Joueur values(null,'Köpke','Andreas','Pro',13);
-- INSERT into Joueur values(null,'Zinedine','Zidane','Pro',14);
-- INSERT into Joueur values(null,'Barthez','Fabien','Pro',14);
-- INSERT into Joueur values(null,'Waddle','Chris','Pro',14);
-- INSERT into Joueur values(null,'Pernambucano','Juninho','Pro',15);
-- INSERT into Joueur values(null,'Gomez','Yohan','Pro',15);
-- INSERT into Joueur values(null,'Hartock','Joan','Pro',15);
-- INSERT into Joueur values(null,'Vieira','Marcelo','Pro',16);
-- INSERT into Joueur values(null,'Lunin','Andriy','Pro',16);
-- INSERT into Joueur values(null,'Modric','Luka','Pro',16);





-- INSERT into Joueur values(null,'Junior','Napo','loisir',17);
-- INSERT into Joueur values(null,'Junior','Nelson','loisir',17);
-- INSERT into Joueur values(null,'Junior','Archie','loisir',17);
-- INSERT into Joueur values(null,'Splinter','Donatello','loisir',18);
-- INSERT into Joueur values(null,'Splinter','Leonardo','loisir',18);
-- INSERT into Joueur values(null,'Splinter','Raphaelo','loisir',18);


-- INSERTION Inscrit

-- Insert into Inscrit values(1,1,null);
-- Insert into Inscrit values(1,2,null);
-- Insert into Inscrit values(1,3,null);
-- Insert into Inscrit values(1,4,null);
-- Insert into Inscrit values(2,5,null);
-- Insert into Inscrit values(2,6,null);

-- INSERTION Tour

-- Insert into Tour values(null,"quart-FinalPRO",1,'encours',1);
-- Insert into Tour values(null,"Demi-FinalPRO",2,'termine',1);
-- Insert into Tour values(null,"FinalPRO",3,'termine',1);

-- Insert into Tour values(null,"FinalPRO",2,null,1);
-- Insert into Tour values(null,"FinalPOUSSIN",1,null,2);


-- INSERTION Terrain

-- Insert into Terrain values(null,"Football");
-- Insert into Terrain values(null,"Football");
-- Insert into Terrain values(null,"Football");
-- Insert into Terrain values(null,"Football");
-- Insert into Terrain values(null,"Football");
-- Insert into Terrain values(null,"Football");
-- Insert into Terrain values(null,"Football");
-- Insert into Terrain values(null,"Football");
-- Insert into Terrain values(null,"Football");
-- Insert into Terrain values(null,"Football");
-- Insert into Terrain values(null,"Football");
-- Insert into Terrain values(null,"Football");
-- Insert into Terrain values(null,"Football");
-- Insert into Terrain values(null,"Football");
-- Insert into Terrain values(null,"Football");

-- Insert into Terrain values(null,"Basket-ball");

-- INSERTION Poule

-- Insert into Poule values(null,"Poule 1",1,1);
-- Insert into Poule values(null,"Poule 2",1,2);
-- Insert into Poule values(null,"Poule 3",1,3);
-- Insert into Poule values(null,"Poule 4",1,4);

-- INSERTION Joue

-- INSERT into Joue values(1,1,2,1,3);
-- INSERT into Joue values(1,2,1,1,10);
-- INSERT into Joue values(1,3,1,3,1);
-- INSERT into Joue values(1,4,1,5,4);

-- INSERT into Joue values(2,5,1,1,2);
-- INSERT into Joue values(2,6,2,2,2);
-- INSERT into Joue values(2,7,1,8,103);
-- INSERT into Joue values(2,8,2,1,97);

-- INSERT into Joue values(3,9,1,1,97);
-- INSERT into Joue values(3,10,1,3,12);
-- INSERT into Joue values(3,11,2,1,1);
-- INSERT into Joue values(3,12,1,1,4);

-- INSERT into Joue values(4,13,1,1,20);
-- INSERT into Joue values(4,14,2,1,2);
-- INSERT into Joue values(4,15,1,1,103);
-- INSERT into Joue values(4,16,1,1,97);


--	Organisateur (Pseudo, NomOrganisateur, PrenomOrganisateur, Mdp) 
--	Evenement (IdEvenement, NomEvenement, LieuEvenement, DateEvenement, TypeJeu, NbJoueur, PseudoOrganisateur,Statue)
--	Tournoi (IdTournoi, Categorie,TypeTournoi, IdEvenement)  
--	Equipe (IdEquipe, NomEquipe, NiveauEquipe, NomClub, IdTournoi,InscriptionValidee) 
--	Joueur (IdJoueur, NomJoueur, PrenomJoueur, NiveauJoueur, IdEquipe)
--	Tour (IdTour, NomTour, NumTour, Statue, IdTournoi) 
--	Poule (IdPoule, NomPoule, IdTour, NumTerrain) 
--	Terrain (NumTerrain, TypeJeu)
--	Joue (IdPoule, IdEquipe, NbMatch, NbSet, NbPoint) 
--	Sport(TypeJeu)


-- trigger:
-- les evenement passé doivent être supprimés
-- quand un tour termine, ses poules auront un terrain null
-- quand un evemenet commence, les equipes inscrits dans ses tournois qui n'ont pas validé leur inscription seront supprimer
-- 
-- 
-- 

-- SHOW PROCESSLIST;
-- SHOW EVENTS;

-- Insert into Evenement values (null,'Event test','Londre','2020-12-09','Football',3,'MaradonaGod','bientot');

-- CALL remove_canceled_evenement();
