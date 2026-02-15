# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    # ------------------------------------------------------------------
    # Shared: every authenticated user can manage their own profile
    # ------------------------------------------------------------------
    can :manage, EncryptedUserConfig, user_id: user.id
    can :manage, UserConfig, user_id: user.id
    can :manage, User, id: user.id

    # Every user can read their own account (for display purposes)
    can :read, Account, id: user.account_id

    case user.role
    when User::ADMIN_ROLE   then admin_abilities(user)
    when User::MANAGER_ROLE then manager_abilities(user)
    when User::EDITOR_ROLE  then editor_abilities(user)
    when User::VIEWER_ROLE  then viewer_abilities(user)
    end
  end

  private

  # ====================================================================
  # ADMIN — Full access to everything within the account
  # ====================================================================
  def admin_abilities(user)
    can :manage, Template, Abilities::TemplateConditions.collection(user) do |template|
      Abilities::TemplateConditions.entity(template, user:, ability: 'manage')
    end

    can :destroy, Template, account_id: user.account_id
    can :manage, TemplateFolder, account_id: user.account_id
    can :manage, TemplateSharing, template: { account_id: user.account_id }
    can :manage, Submission, account_id: user.account_id
    can :manage, Submitter, account_id: user.account_id
    can :manage, User, account_id: user.account_id
    can :manage, EncryptedConfig, account_id: user.account_id
    can :manage, AccountConfig, account_id: user.account_id
    can :manage, Account, id: user.account_id
    can :manage, AccessToken, user_id: user.id
    can :manage, WebhookUrl, account_id: user.account_id
  end

  # ====================================================================
  # MANAGER — Templates, submissions, users, notifications,
  #           personalization. No system settings (SMTP, storage, SSO,
  #           e-signature certs, API tokens).
  # ====================================================================
  def manager_abilities(user)
    # Templates: full CRUD
    can %i[read create update], Template, Abilities::TemplateConditions.collection(user) do |template|
      Abilities::TemplateConditions.entity(template, user:, ability: 'manage')
    end
    can :destroy, Template, account_id: user.account_id
    can :manage, TemplateFolder, account_id: user.account_id
    can :manage, TemplateSharing, template: { account_id: user.account_id }

    # Submissions: full CRUD
    can :manage, Submission, account_id: user.account_id
    can :manage, Submitter, account_id: user.account_id

    # Users: can view all, invite new, edit others (but not change their own role)
    can %i[read create update], User, account_id: user.account_id
    # Managers can archive non-admin users
    can :destroy, User, account_id: user.account_id

    # Notifications & personalization
    can :manage, AccountConfig, account_id: user.account_id

    # Webhooks: read-only (can view but not create/delete)
    can :read, WebhookUrl, account_id: user.account_id
  end

  # ====================================================================
  # EDITOR — Create & edit templates and submissions.
  #          Cannot delete templates, manage users, or access settings.
  # ====================================================================
  def editor_abilities(user)
    # Templates: create, read, update — no delete
    can %i[read create update], Template, Abilities::TemplateConditions.collection(user) do |template|
      Abilities::TemplateConditions.entity(template, user:, ability: 'manage')
    end
    can :manage, TemplateFolder, account_id: user.account_id
    can :read, TemplateSharing, template: { account_id: user.account_id }

    # Submissions: full CRUD (editors need to send and manage submissions)
    can :manage, Submission, account_id: user.account_id
    can :manage, Submitter, account_id: user.account_id

    # Users: read-only (can see the team list but not manage)
    can :read, User, account_id: user.account_id
  end

  # ====================================================================
  # VIEWER — Read-only access to templates and submissions.
  #          Cannot create, edit, or delete anything except own profile.
  # ====================================================================
  def viewer_abilities(user)
    can :read, Template, Abilities::TemplateConditions.collection(user) do |template|
      Abilities::TemplateConditions.entity(template, user:, ability: 'read')
    end
    can :read, TemplateFolder, account_id: user.account_id
    can :read, Submission, account_id: user.account_id
    can :read, Submitter, account_id: user.account_id
    can :read, User, account_id: user.account_id
  end
end
