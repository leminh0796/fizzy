class Users::AvatarsController < ApplicationController
  include ActiveStorage::Streaming

  before_action :set_user

  def show
    if stale? @user, cache_control: { max_age: cache_max_age, stale_while_revalidate: 1.week }
      render_avatar_or_initials
    end
  end

  def destroy
    @user.avatar.destroy
    redirect_to user_path(@user)
  end

  private
    def cache_max_age
      if Current.user == @user
        0
      else
        30.minutes
      end
    end

    def set_user
      @user = Current.account.users.find(params[:user_id])
    end

    def render_avatar_or_initials
      if @user.avatar.attached?
        send_blob_stream @user.avatar
      else
        render_initials
      end
    end

    def render_initials
      render formats: :svg
    end
end
