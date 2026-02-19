require "rails_helper"

RSpec.describe ManagerInvitation, type: :model do
  let(:admin) { create(:user, :super_admin) }

  subject { create(:manager_invitation, created_by: admin) }

  describe "validations" do
    it { is_expected.to be_valid }
    it { is_expected.to validate_uniqueness_of(:code) }
    it { is_expected.to validate_presence_of(:manager_name) }
    it { is_expected.to validate_presence_of(:manager_email) }

    it "validates email format" do
      subject.manager_email = "not-an-email"
      expect(subject).not_to be_valid
      expect(subject.errors[:manager_email]).to be_present
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:created_by).class_name("User") }
    it { is_expected.to belong_to(:claimed_by).class_name("User").optional }
  end

  describe "before_validation callbacks" do
    it "auto-generates a 6-character code on create" do
      invitation = build(:manager_invitation, created_by: admin, code: nil)
      invitation.valid?
      expect(invitation.code).to match(/\A[A-Z0-9]{6}\z/)
    end

    it "auto-sets expires_at to 30 days from now" do
      invitation = build(:manager_invitation, created_by: admin, expires_at: nil)
      invitation.valid?
      expect(invitation.expires_at).to be_within(1.minute).of(30.days.from_now)
    end
  end

  describe "scopes" do
    describe ".available" do
      it "includes active, unclaimed, non-expired invitations" do
        invitation = create(:manager_invitation, created_by: admin)
        expect(ManagerInvitation.available).to include(invitation)
      end

      it "excludes inactive invitations" do
        invitation = create(:manager_invitation, created_by: admin, active: false)
        expect(ManagerInvitation.available).not_to include(invitation)
      end

      it "excludes claimed invitations" do
        claimant = create(:user, :property_manager)
        invitation = create(:manager_invitation, created_by: admin, claimed_by: claimant)
        expect(ManagerInvitation.available).not_to include(invitation)
      end

      it "excludes expired invitations" do
        invitation = create(:manager_invitation, created_by: admin, expires_at: 1.day.ago)
        expect(ManagerInvitation.available).not_to include(invitation)
      end
    end
  end

  describe "#claimed?" do
    it "returns false when not claimed" do
      expect(subject.claimed?).to be false
    end

    it "returns true when claimed" do
      subject.claimed_by = create(:user, :property_manager)
      expect(subject.claimed?).to be true
    end
  end

  describe "#expired?" do
    it "returns false when not expired" do
      subject.expires_at = 1.day.from_now
      expect(subject.expired?).to be false
    end

    it "returns true when expired" do
      subject.expires_at = 1.day.ago
      expect(subject.expired?).to be true
    end
  end

  describe "#available?" do
    it "returns true for active, unclaimed, non-expired invitation" do
      expect(subject.available?).to be true
    end

    it "returns false when inactive" do
      subject.active = false
      expect(subject.available?).to be false
    end

    it "returns false when claimed" do
      subject.claimed_by = create(:user, :property_manager)
      expect(subject.available?).to be false
    end

    it "returns false when expired" do
      subject.expires_at = 1.day.ago
      expect(subject.available?).to be false
    end
  end
end
