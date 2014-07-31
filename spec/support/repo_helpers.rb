module RepoHelpers
  extend self

  # Text file in repo
  #
  # Ex.
  #
  #   # Get object
  #   blob = RepoHelpers.text_blob
  #
  #   blob.path # => 'files/js/commit.js.coffee'
  #   blob.data # => 'class Commit...'
  #
  def sample_blob
    OpenStruct.new(
      path: "files/js/commit.js.coffee",
      data: <<eos
class Commit
  constructor: ->
    $('.files .diff-file').each ->
      new CommitFile(this)

@Commit = Commit
eos
    )
  end

  def sample_commit
    OpenStruct.new(
      id: "570e7b2abdd848b95f2f578043fc23bd6f6fd24d",
      parent_id: '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9',
      author_full_name: "Dmitriy Zaporozhets",
      author_email: "dmitriy.zaporozhets@gmail.com",
      files_changed_count: 2,
      line_code: '2f6fcd96b88b36ce98c38da085c795a27d92a3dd_15_14',
      del_line_code: '2f6fcd96b88b36ce98c38da085c795a27d92a3dd_13_13',
      message: <<eos
Change some files
Signed-off-by: Dmitriy Zaporozhets <dmitriy.zaporozhets@gmail.com>
eos
    )
  end

  def sample_big_commit
    OpenStruct.new(
      id: "913c66a37b4a45b9769037c55c2d238bd0942d2e",
      author_full_name: "Dmitriy Zaporozhets",
      author_email: "dmitriy.zaporozhets@gmail.com",
      message: <<eos
Files, encoding and much more
Signed-off-by: Dmitriy Zaporozhets <dmitriy.zaporozhets@gmail.com>
eos
    )
  end

  def sample_image_commit
    OpenStruct.new(
      id: "2f63565e7aac07bcdadb654e253078b727143ec4",
      author_full_name: "Dmitriy Zaporozhets",
      author_email: "dmitriy.zaporozhets@gmail.com",
      old_blob_id: '33f3729a45c02fc67d00adb1b8bca394b0e761d9',
      new_blob_id: '2f63565e7aac07bcdadb654e253078b727143ec4',
      message: <<eos
Modified image
Signed-off-by: Dmitriy Zaporozhets <dmitriy.zaporozhets@gmail.com>
eos
    )
  end
end
