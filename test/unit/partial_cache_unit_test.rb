# frozen_string_literal: true

require 'test_helper'

class PartialCacheUnitTest < Minitest::Test
  def test_uses_the_file_system_register_if_present
    context = Liquid::Context.build(
      registers: {
        file_system: StubFileSystem.new('my_partial' => 'my partial body'),
      }
    )

    partial = Liquid::PartialCache.load(
      'my_partial',
      context: context,
      parse_context: Liquid::ParseContext.new
    )

    assert_equal('my partial body', partial.render)
  end

  def test_reads_from_the_file_system_only_once_per_file
    file_system = StubFileSystem.new('my_partial' => 'some partial body')
    context = Liquid::Context.build(
      registers: { file_system: file_system }
    )

    2.times do
      Liquid::PartialCache.load(
        'my_partial',
        context: context,
        parse_context: Liquid::ParseContext.new
      )
    end

    assert_equal(1, file_system.file_read_count)
  end

  def test_cache_state_is_stored_per_context
    parse_context = Liquid::ParseContext.new
    shared_file_system = StubFileSystem.new(
      'my_partial' => 'my shared value'
    )
    context_one = Liquid::Context.build(
      registers: {
        file_system: shared_file_system,
      }
    )
    context_two = Liquid::Context.build(
      registers: {
        file_system: shared_file_system,
      }
    )

    2.times do
      Liquid::PartialCache.load(
        'my_partial',
        context: context_one,
        parse_context: parse_context
      )
    end

    Liquid::PartialCache.load(
      'my_partial',
      context: context_two,
      parse_context: parse_context
    )

    assert_equal(2, shared_file_system.file_read_count)
  end

  def test_cache_is_not_broken_when_a_different_parse_context_is_used
    file_system = StubFileSystem.new('my_partial' => 'some partial body')
    context = Liquid::Context.build(
      registers: { file_system: file_system }
    )

    Liquid::PartialCache.load(
      'my_partial',
      context: context,
      parse_context: Liquid::ParseContext.new(my_key: 'value one')
    )
    Liquid::PartialCache.load(
      'my_partial',
      context: context,
      parse_context: Liquid::ParseContext.new(my_key: 'value two')
    )

    # Technically what we care about is that the file was parsed twice,
    # but measuring file reads is an OK proxy for this.
    assert_equal(1, file_system.file_read_count)
  end
end
