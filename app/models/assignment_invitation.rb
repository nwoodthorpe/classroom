# frozen_string_literal: true
class AssignmentInvitation < ApplicationRecord
  default_scope { where(deleted_at: nil) }

  update_index('stafftools#assignment_invitation') { self }

  has_one :organization, through: :assignment

  belongs_to :assignment

  validates :assignment, presence: true

  validates :key, presence:   true
  validates :key, uniqueness: true

  after_initialize :assign_key

  # Public: Redeem an AssignmentInvtiation for a User invitee.
  #
  # Returns a AssignmentRepo::Creator::Result.
  def redeem_for(invitee)
    if (repo_access = RepoAccess.find_by(user: invitee, organization: organization))
      assignment_repo = AssignmentRepo.find_by(assignment: assignment, repo_access: repo_access)
      return AssignmentRepo::Creator::Result.success(assignment_repo) if assignment_repo.present?
    end

    assignment_repo = AssignmentRepo.find_by(assignment: assignment, user: invitee)
    return AssignmentRepo::Creator::Result.success(assignment_repo) if assignment_repo.present?

    AssignmentRepo::Creator.perform(assignment: assignment, user: invitee)
  end

  def title
    assignment.title
  end

  def to_param
    key
  end

  protected

  def assign_key
    self.key ||= SecureRandom.hex(16)
  end
end
