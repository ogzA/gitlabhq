require 'spec_helper'

describe Gitlab::SlashCommands::Extractor do
  let(:definitions) do
    Class.new do
      include Gitlab::SlashCommands::Dsl

      command(:reopen, :open) { }
      command(:assign) { }
      command(:labels) { }
      command(:power) { }
    end.command_definitions
  end

  let(:extractor) { described_class.new(definitions) }

  shared_examples 'command with no argument' do
    it 'extracts command' do
      msg, commands = extractor.extract_commands(original_msg)

      expect(commands).to eq [['reopen']]
      expect(msg).to eq final_msg
    end
  end

  shared_examples 'command with a single argument' do
    it 'extracts command' do
      msg, commands = extractor.extract_commands(original_msg)

      expect(commands).to eq [['assign', '@joe']]
      expect(msg).to eq final_msg
    end
  end

  shared_examples 'command with multiple arguments' do
    it 'extracts command' do
      msg, commands = extractor.extract_commands(original_msg)

      expect(commands).to eq [['labels', '~foo ~"bar baz" label']]
      expect(msg).to eq final_msg
    end
  end

  describe '#extract_commands' do
    describe 'command with no argument' do
      context 'at the start of content' do
        it_behaves_like 'command with no argument' do
          let(:original_msg) { "/reopen\nworld" }
          let(:final_msg) { "world" }
        end
      end

      context 'in the middle of content' do
        it_behaves_like 'command with no argument' do
          let(:original_msg) { "hello\n/reopen\nworld" }
          let(:final_msg) { "hello\nworld" }
        end
      end

      context 'in the middle of a line' do
        it 'does not extract command' do
          msg = "hello\nworld /reopen"
          msg, commands = extractor.extract_commands(msg)

          expect(commands).to be_empty
          expect(msg).to eq "hello\nworld /reopen"
        end
      end

      context 'at the end of content' do
        it_behaves_like 'command with no argument' do
          let(:original_msg) { "hello\n/reopen" }
          let(:final_msg) { "hello" }
        end
      end
    end

    describe 'command with a single argument' do
      context 'at the start of content' do
        it_behaves_like 'command with a single argument' do
          let(:original_msg) { "/assign @joe\nworld" }
          let(:final_msg) { "world" }
        end

        it 'allows slash in command arguments' do
          msg = "/assign @joe / @jane\nworld"
          msg, commands = extractor.extract_commands(msg)

          expect(commands).to eq [['assign', '@joe / @jane']]
          expect(msg).to eq 'world'
        end
      end

      context 'in the middle of content' do
        it_behaves_like 'command with a single argument' do
          let(:original_msg) { "hello\n/assign @joe\nworld" }
          let(:final_msg) { "hello\nworld" }
        end
      end

      context 'in the middle of a line' do
        it 'does not extract command' do
          msg = "hello\nworld /assign @joe"
          msg, commands = extractor.extract_commands(msg)

          expect(commands).to be_empty
          expect(msg).to eq "hello\nworld /assign @joe"
        end
      end

      context 'at the end of content' do
        it_behaves_like 'command with a single argument' do
          let(:original_msg) { "hello\n/assign @joe" }
          let(:final_msg) { "hello" }
        end
      end

      context 'when argument is not separated with a space' do
        it 'does not extract command' do
          msg = "hello\n/assign@joe\nworld"
          msg, commands = extractor.extract_commands(msg)

          expect(commands).to be_empty
          expect(msg).to eq "hello\n/assign@joe\nworld"
        end
      end
    end

    describe 'command with multiple arguments' do
      context 'at the start of content' do
        it_behaves_like 'command with multiple arguments' do
          let(:original_msg) { %(/labels ~foo ~"bar baz" label\nworld) }
          let(:final_msg) { "world" }
        end
      end

      context 'in the middle of content' do
        it_behaves_like 'command with multiple arguments' do
          let(:original_msg) { %(hello\n/labels ~foo ~"bar baz" label\nworld) }
          let(:final_msg) { "hello\nworld" }
        end
      end

      context 'in the middle of a line' do
        it 'does not extract command' do
          msg = %(hello\nworld /labels ~foo ~"bar baz" label)
          msg, commands = extractor.extract_commands(msg)

          expect(commands).to be_empty
          expect(msg).to eq %(hello\nworld /labels ~foo ~"bar baz" label)
        end
      end

      context 'at the end of content' do
        it_behaves_like 'command with multiple arguments' do
          let(:original_msg) { %(hello\n/labels ~foo ~"bar baz" label) }
          let(:final_msg) { "hello" }
        end
      end

      context 'when argument is not separated with a space' do
        it 'does not extract command' do
          msg = %(hello\n/labels~foo ~"bar baz" label\nworld)
          msg, commands = extractor.extract_commands(msg)

          expect(commands).to be_empty
          expect(msg).to eq %(hello\n/labels~foo ~"bar baz" label\nworld)
        end
      end
    end

    it 'extracts command with multiple arguments and various prefixes' do
      msg = %(hello\n/power @user.name %9.10 ~"bar baz.2"\nworld)
      msg, commands = extractor.extract_commands(msg)

      expect(commands).to eq [['power', '@user.name %9.10 ~"bar baz.2"']]
      expect(msg).to eq "hello\nworld"
    end

    it 'extracts multiple commands' do
      msg = %(hello\n/power @user.name %9.10 ~"bar baz.2" label\nworld\n/reopen)
      msg, commands = extractor.extract_commands(msg)

      expect(commands).to eq [['power', '@user.name %9.10 ~"bar baz.2" label'], ['reopen']]
      expect(msg).to eq "hello\nworld"
    end

    it 'does not alter original content if no command is found' do
      msg = 'Fixes #123'
      msg, commands = extractor.extract_commands(msg)

      expect(commands).to be_empty
      expect(msg).to eq 'Fixes #123'
    end

    it 'does not extract commands inside a blockcode' do
      msg = "Hello\r\n```\r\nThis is some text\r\n/close\r\n/assign @user\r\n```\r\n\r\nWorld"
      expected = msg.delete("\r")
      msg, commands = extractor.extract_commands(msg)

      expect(commands).to be_empty
      expect(msg).to eq expected
    end

    it 'does not extract commands inside a blockquote' do
      msg = "Hello\r\n>>>\r\nThis is some text\r\n/close\r\n/assign @user\r\n>>>\r\n\r\nWorld"
      expected = msg.delete("\r")
      msg, commands = extractor.extract_commands(msg)

      expect(commands).to be_empty
      expect(msg).to eq expected
    end

    it 'does not extract commands inside a HTML tag' do
      msg = "Hello\r\n<div>\r\nThis is some text\r\n/close\r\n/assign @user\r\n</div>\r\n\r\nWorld"
      expected = msg.delete("\r")
      msg, commands = extractor.extract_commands(msg)

      expect(commands).to be_empty
      expect(msg).to eq expected
    end
  end
end
