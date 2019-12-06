require_relative 'base_connection.rb'

QuestionsDatabase = BaseDatabaseConnection.new('questions.db')

# our magic classes get us most of what we need: every find_by_x class method on our table derived objects, and getter methods for the attributes. We need to work on the singularization of plurals. Currently, the replies table becomes a Replie class, and question_follows becomes Question_follow.

# we'll still need to define exercise specific methods
# most of them could be done away with once we implement relations in our BaseModel, though they'd likely have different names

class Question
  def self.most_liked(n)
    Question_like.most_liked_questions(n)
  end

  def author
    User.find_by_id(self.author_id)
  end

  def replies
    Replie.find_by_question_id(self.id)
  end

  def followers
    Question_follow.followers_for_question_id(self.id)
  end

  def most_followed(n)
    Question_follow.most_followed_questions(n)
  end

  def likers
    Question_like.likers_for_question_id(self.id)
  end

  def num_likes
    Question_like.num_likes_for_question_id(self.id)
  end
end

class User
  def authored_questions
    Question.find_by_author_id(self.id)
  end

  def authored_replies
    Replie.find_by_user_id(self.id)
  end

  def followed_questions
    Question_follow.followed_questions_for_user_id(self.id)
  end

  def liked_questions
    Question_like.liked_questions_for_user_id(self.id)
  end

  def average_karma
    # doing this with JOINs is just plain silly. consider:
    authored_questions.count / liked_questions.count.to_f
    # but in the spirit of the nonsense:
  end
end

class Replie
  def author
    User.find_by_id(self.user_id)
  end

  def question
    Question.find_by_id(self.quesion_id)
  end

  def parent_reply
    id = self.parent_reply_id || self.id
    Replie.find_by_id(id)
  end

  def child_replies
    Replie.find_by_parent_reply_id(self.id)
  end
end

class Question_follow
  def self.followers_for_question_id(quesion_id)
    users = Question_follow.find_by_question_id(quesion_id)
    if users.class == Array
      users.map { |user| User.find_by_id(user.follower_id) }
    elsif users.class == Question_follow
      User.find_by_id(users.follower_id)
    end
  end

  def self.followed_questions_for_user_id(user_id)
    questions = Question_follow.find_by_follower_id(user_id)
    if questions.class == Array
      questions.map { |question| Question.find_by_id(question.question_id) }
    elsif questions.class == Question_follow
      Question.find_by_id(questions.question_id)
    end
  end

  def self.most_followed_questions(n)
    # SELECT * FROM #{@name} #{query}
    questions = Question_follow.query("question_id", <<-SQL)
      GROUP BY
        question_id
      ORDER BY
        COUNT(question_id) DESC
      LIMIT #{n}
    SQL

    questions.map { |question| Question.find_by_id(question["question_id"]) }
  end
end

class Question_like
  def self.likers_for_question_id(question_id)
    users = Question_like.query("liker_id", <<-SQL)
      WHERE
        question_id = #{question_id}
    SQL

    users.map { |user| User.find_by_id(user["liker_id"]) }
  end

  def self.num_likes_for_question_id(question_id)
    num = Question_like.query("COUNT(liker_id)", <<-SQL)
      WHERE
        question_id = #{question_id}
    SQL
    
    num[0]["COUNT(liker_id)"]
  end

  def self.liked_questions_for_user_id(user_id)
    questions = Question_like.query("question_id", <<-SQL)
      WHERE
        liker_id = #{user_id}
    SQL

    questions.map { |question| Question.find_by_id(question["question_id"]) }
  end

  def self.most_liked_questions(n)
    questions = Question_like.query("question_id", <<-SQL)
      GROUP BY
        question_id
      ORDER BY
        COUNT(question_id) DESC
      LIMIT #{n}
    SQL

    questions.map { |question| Question.find_by_id(question["question_id"]) }
  end
end