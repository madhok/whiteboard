# GradingRule represents the correspondence between points earned and letter grades. The mapping rule is given by the
# course instructor.
#
# GradingRule is configurable by clicking on "Configure course" in "Initial Course Configuration", both of which could
# be found on the index page of each course. In the configuration page, professor can choose grading criteria between
#   points and letter grades. If professor adopts letter grades, then professor needs to fill the table which maps out
#   point and letter grades.
#
# GradingRule follows the grading policy of CMU@SV. We provide the following options for letter grades: A, A-, B+, B,
#   B-, C+, C, C-.
#
# We provide the following functions to map out points and letter grades.
# * validate_letter_grade performs letter grade validation for the given score.
# * validate_score performs score validation for the given score by the grade type
# * format_score formats the given score
# * convert_points_to_letter_grade maps out points to letter grades.
# * convert_letter_grade_to_points maps out letter grades to points.
# * to_display
# * get_grade_params_for_javascript

class GradingRule < ActiveRecord::Base
  attr_accessible :grade_type,
                  :A_grade_min,
                  :A_minus_grade_min,
                  :B_plus_grade_min,
                  :B_grade_min,
                  :B_minus_grade_min,
                  :C_plus_grade_min,
                  :C_grade_min,
                  :C_minus_grade_min,
                  :course_id,
                  :is_nomenclature_deliverable

  belongs_to :course

  # To perform letter grade validation for the given score.
  def validate_letter_grade(raw_score)
    mapping_rule.has_key?(raw_score.to_s.upcase)
  end

  # To perform validation for the given score by the grade type
  def validate_score(raw_score)
    # allow users to skip entering grades
    if raw_score.nil? || raw_score.empty?
      return true
    end

    # To allow users to enter letter grades
    if mapping_rule.has_key?(raw_score.to_s.upcase)
      return true
    end

    case grade_type
      when "points"
        return validate_points(raw_score)
      when "weights"
        return validate_weights(raw_score)
      else
        return false
    end
  end

  # To format the given score
  def self.format_score (course_id, raw_score)
    raw_score=raw_score.to_s
    grading_rule = GradingRule.find_by_course_id(course_id)
    if grading_rule.nil?
      return raw_score
    elsif grading_rule.grade_type=="weights" && raw_score.end_with?("%")
      return raw_score.split("%")[0]
    else
      return raw_score
   end
  end

  # To convert points to letter grades
  def convert_points_to_letter_grade (points)
    if points>=self.A_grade_min
      return "A"
    elsif points>=self.A_minus_grade_min
        return "A-"
    elsif points>=self.B_plus_grade_min
      return "B+"
    elsif points>=self.B_grade_min
      return "B"
    elsif points>=self.B_minus_grade_min
      return "B-"
    elsif points>=self.C_plus_grade_min
      return "C+"
    elsif points>=self.C_grade_min
      return "C"
    elsif points>=self.C_minus_grade_min
      return "C-"
    else
      return 0.to_s
    end
  end

  # To convert letter grades to points
  def convert_letter_grade_to_points (letter_grade)
    (mapping_rule.has_key?(letter_grade)?mapping_rule[letter_grade]:-1.0)
  end

  def to_display
    unless self.is_nomenclature_deliverable?
      return "Assignment"
    else
      return "Deliverable"
    end
  end

  def self.get_grade_type (course_id)
    grading_rule = GradingRule.find_by_course_id(course_id)
    if grading_rule.nil?
      return "points"
    end

    return grading_rule.grade_type
  end

  def get_grade_params_for_javascript
    weight_hash = []
    self.course.assignments.each do |assignment|
      score = assignment.maximum_score
      if self.grade_type == "weights"
        score *= 0.01
      end
      weight_hash << score
    end
    "'#{GradingRule.get_grade_type self.course_id}', #{mapping_rule.to_json}, #{weight_hash.to_json}"
  end

  def letter_grades
    @letter_grades ||= mapping_rule.keys
  end

private
  def mapping_rule
    @mapping_rule ||= {
        "A"=>100, "A-"=>self.A_grade_min-0.1,
        "B+"=>self.A_minus_grade_min-0.1, "B"=>self.B_plus_grade_min-0.1, "B-"=>self.B_grade_min-0.1,
        "C+"=>self.B_minus_grade_min-0.1, "C"=>self.C_plus_grade_min-0.1, "C-"=>self.C_grade_min-0.1,
        "R"=>0, "W"=>0, "I"=>0
    }
  end

  def validate_points(raw_score)
    if raw_score.to_i<0
      return false
    end
    true if Float(raw_score) rescue false
  end

  def validate_weights(raw_score)
    if raw_score.end_with?("%")
      raw_score = raw_score.split('%')[0]
    end
    return validate_points(raw_score)
  end

end