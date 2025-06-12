require "test_helper"

class CollectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as :kevin
  end

  test "new" do
    get new_collection_path
    assert_response :success
  end

  test "create" do
    assert_difference -> { Collection.count }, +1 do
      post collections_path, params: { collection: { name: "Remodel Punch List" } }
    end

    collection = Collection.last
    assert_redirected_to cards_path(collection_ids: [ collection ])
    assert_includes collection.users, users(:kevin)
    assert_equal "Remodel Punch List", collection.name
  end

  test "edit" do
    get edit_collection_path(collections(:writebook))
    assert_response :success
  end

  test "update" do
    patch collection_path(collections(:writebook)), params: {
      collection: {
        name: "Writebook bugs",
        all_access: false,
        auto_close_period: 1.day,
        auto_reconsider_period: 2.days
      },
      user_ids: users(:david, :jz).pluck(:id)
    }

    assert_redirected_to edit_collection_path(collections(:writebook))
    assert_equal "Writebook bugs", collections(:writebook).reload.name
    assert_equal users(:david, :jz).sort, collections(:writebook).users.sort
    assert_equal 1.day, entropy_configurations(:writebook_collection).auto_close_period
    assert_equal 2.days, entropy_configurations(:writebook_collection).auto_reconsider_period
    assert_not collections(:writebook).all_access?
  end

  test "update collection with granular permissions, submitting no user ids" do
    assert_not collections(:private).all_access?

    collections(:private).users = [ users(:kevin) ]
    collections(:private).save!

    patch collection_path(collections(:private)), params: {
      collection: { name: "Renamed" }
    }

    assert_redirected_to edit_collection_path(collections(:private))
    assert_equal "Renamed", collections(:private).reload.name
    assert_equal [ users(:kevin) ], collections(:private).users
    assert_not collections(:private).all_access?
  end

  test "update all access" do
    collection = Current.set(session: sessions(:kevin)) do
      Collection.create! name: "New collection", all_access: false
    end
    assert_equal [ users(:kevin) ], collection.users

    patch collection_path(collection), params: { collection: { name: "Bugs", all_access: true } }

    assert_redirected_to edit_collection_path(collection)
    assert collection.reload.all_access?
    assert_equal User.all, collection.users
  end

  test "destroy" do
    collection = collections(:writebook)
    delete collection_path(collection)
    assert_redirected_to root_path
    assert_raises(ActiveRecord::RecordNotFound) { collection.reload }
  end
end
