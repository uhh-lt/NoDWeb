# --- !Ups

CREATE TABLE entities (
  id BIGINT,
  type INT NOT NULL,
  name VARCHAR(255) NOT NULL,
  CONSTRAINT entities_pkey PRIMARY KEY(id)
) ENGINE = MyISAM;

CREATE TABLE tweets (
  id BIGINT NOT NULL AUTO_INCREMENT,
  created DATE NOT NULL,
  message varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  CONSTRAINT tweet_pkey PRIMARY KEY(id)
) ENGINE = MyISAM;

CREATE TABLE entities_to_tweets (
  entity_id BIGINT NOT NULL, 	   -- REFERENCES entities(id)
  tweet_id BIGINT NOT NULL         -- REFERENCES sentences(id)
) ENGINE = MyISAM;


# --- !Downs

DROP TABLE entities;
DROP TABLE tweets;
DROP TABLE entities_to_tweets;
