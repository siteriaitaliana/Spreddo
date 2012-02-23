class CreateFeeds < ActiveRecord::Migration
  def change
    create_table :feeds do |t|
      t.string :source
      t.string :title
      t.text :content

      t.timestamps
    end
  end
end
