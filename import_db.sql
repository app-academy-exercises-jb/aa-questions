PRAGMA foreign_keys = OFF;

DROP TABLE IF EXISTS question_follows;
DROP TABLE IF EXISTS question_likes;
DROP TABLE IF EXISTS replies;
DROP TABLE IF EXISTS questions;
DROP TABLE IF EXISTS users;

PRAGMA foreign_keys = ON;

CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname TEXT NOT NULL,
  lname TEXT NOT NULL
);

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  author_id INTEGER NOT NULL,

  FOREIGN KEY (author_id) REFERENCES users(id)
);

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  body TEXT NOT NULL,
  parent_reply_id INTEGER DEFAULT NULL,

  FOREIGN KEY (user_id)
    REFERENCES users(id)
      ON DELETE CASCADE
      ON UPDATE NO ACTION,

  FOREIGN KEY (question_id)
    REFERENCES questions(id)
      ON DELETE CASCADE
      ON UPDATE NO ACTION,

  FOREIGN KEY (parent_reply_id)
    REFERENCES replies(id)
      ON DELETE CASCADE
      ON UPDATE NO ACTION
);

CREATE TABLE question_follows (
  follower_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,
  PRIMARY KEY (follower_id, question_id),
  FOREIGN KEY (follower_id)
    REFERENCES users(id)
      ON DELETE CASCADE
      ON UPDATE NO ACTION,
  FOREIGN KEY (question_id)
    REFERENCES questions(id)
      ON DELETE CASCADE
      ON UPDATE NO ACTION
);

CREATE TABLE question_likes (
  liker_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,
  PRIMARY KEY (liker_id, question_id),
  FOREIGN KEY (liker_id)
    REFERENCES users(id)
      ON DELETE CASCADE
      ON UPDATE NO ACTION,
  FOREIGN KEY (question_id)
    REFERENCES questions(id)
      ON DELETE CASCADE
      ON UPDATE NO ACTION
);


INSERT INTO
  users (id, fname, lname)
VALUES
  (1, "Arthur", "Miller"),
  (2, "Eugene", "O''Neill"),
  (3, "Bobby", "Brown"),
  (4, "Scoby", "Johansen"),
  (5, "Metazilla", "Prime");

INSERT INTO
  questions (id, title, body, author_id)
VALUES
  (1, "Arthur's Corner", "What's a guy gotta do to get a latte?", 1),
  (2, "How do I log on here again?", "I cant remember how to log on to the site. Any pointers?", 2),
  (3, "Ruby Singleton Classes", "Would anyone care to explain these to me?", 3),
  (4, "Scoby Care Tips", "So, my scobies have been languishing in their scoby hotel for a while now. Are they going to be ok?", 4),
  (5, "Where am I", "This is a terrible Q/A interface. Has anyone heard of Stack Overflow?", 5);

INSERT INTO
  replies (id, question_id, user_id, body)
VALUES
  (1, 1, 3, "I think there's a vending machine in the hall"),
  (3, 2, 5, "I don't believe that function has been implemented yet"),
  (6, 3, 5, "So, we know that every object in Ruby is an instance of a class. Classes and objects have a one to many relationship; a class can be made any number of instances, however an instantiated object cannot change its class. Singleton Classes, in essence, are classes which have a one-to-one relationship with their object. Each object has a singleton class, which is more immediate in the inheritance chain than the object's class, and which is unique to that object. Class method definitions in regular classes are actually instance methods of that class's singleton class."),
  (7, 3, 1, "So, I went to the hall but found no coffee"),
  (8, 3, 3, "Wrong thread, Boomer. Metaprime: thanks"),
  (9, 4, 5, "Your scobies are fine bro. Don't even trip, dawg."),
  (11, 5, 1, "Coffee?"),
  (13, 5, 5, ":)");

INSERT INTO
  replies (id, question_id, user_id, body, parent_reply_id)
VALUES
  (2, 1, 5, "What hall aren't we in cyberspace??", 1),
  (4, 2, 2, "Oh thanks how are we writing replies then", 3),
  (5, 2, 5, "........", 4),
  (10, 4, 1, "Please I really need coffee how do I get", 9),
  (12, 5, 5, "ruby eval 'a = User.find_by_lname(Miller); a.remove;'", 11);

INSERT INTO
  question_follows (follower_id, question_id)
VALUES
  (1,1),(1,2),(1,3),(1,4),(2,2),(2,4),(3,3),(4,1),(4,4),(5,5);

INSERT INTO
  question_likes (liker_id, question_id)
VALUES
  (1,1),(1,2),(1,3),(1,4),(1,5),(2,2),(2,4),(3,3),(4,1),(4,4),(5,5),(5,4),(5,3),(5,2),(5,1);