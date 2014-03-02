=begin
    Copyright 2010-2014 Tasos Laskos <tasos.laskos@gmail.com>
    All rights reserved.
=end


module Arachni
class Page
class DOM

# @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
class Transition

    # {Transition} error namespace.
    #
    # All {Transition} errors inherit from and live under it.
    #
    # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
    class Error < DOM::Error

        # Raised when an not-applicable action is performed on a completed
        # transition.
        #
        # @see #start
        # @see #complete
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        class Completed < Error
        end

        # Raised when an not-applicable action is performed on a running
        # transition.
        #
        # @see #start
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        class Running < Error
        end

        # Raised when an not-applicable action is performed on a not running
        # transition.
        #
        # @see #complete
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        class NotRunning < Error
        end

        # Raised when an invalid element type is provided.
        #
        # @see #initialize
        # @see #start
        #
        # @author Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>
        class InvalidElement < Error
        end
    end

    # Non-replayable events.
    NON_REPLAYABLE = Set.new([:request, :load])

    # Events without a DOM depth.
    ZERO_DEPTH     = Set.new([:request])

    # @return   [String]
    #   HTML element which received the {#event}.
    attr_reader :element

    # @return   [Symbol]
    #   Event triggered on {#element}.
    attr_reader :event

    # @return   [Hash]
    #   Extra options.
    attr_reader :options

    # @return   [Float]
    #   Time it took to trigger the given {#event} on the {#element}.
    attr_reader :time

    # @note If arguments are provided they will be passed to {#start}.
    #
    # @param    (see #start)
    #
    # @raise    [Error::Completed]
    #   When the transition has been marked as completed.
    # @raise    [Error::Running]
    #   When the transition has already been marked as running.
    # @raise    [Error::InvalidElement]
    #   When an element of invalid type is passed.
    def initialize( *args, &block )
        @options = {}

        return if !args.any?

        start( *args, &block )
    end

    # @param    [String, Symbol]    event
    #   Event associated with this transition -- will be converted to `Symbol`.
    #
    # @return   [Symbol]
    def event=( event )
        @event = event.to_s.to_sym
    end

    # @note Will start the timer for {#time}.
    #
    # @param    [Hash<String,Symbol=>Symbol>]  transition
    #   `resource => event`
    # @param    [Hash]  options
    #   Extra options to associate with this transition.
    # @param    [Block] block
    #   If a `block` has been given it will be executed and the transition will
    #   automatically be marked as {#complete finished}.
    #
    # @return   [Transition]    `self`
    #
    # @raise    [Error::Completed]
    #   When the transition has been marked as completed.
    # @raise    [Error::Running]
    #   When the transition has already been marked as running.
    # @raise    [Error::InvalidElement]
    #   When an element of invalid type is passed.
    def start( transition, options = {}, &block )
        fail Error::Completed, 'Transition has completed.'   if completed?
        fail Error::Running, 'Transition is already running' if running?

        element, self.event = transition.to_a.first

        fail Error::InvalidElement if ![Symbol, String].include?( element.class )

        @element = element

        @options = options
        @clock   = Time.now

        return self if !block_given?

        block.call
        complete
    end

    # @note Will stop the timer for {#time}.
    #
    # Marks the transition as finished.
    #
    # @return   [Transition]    `self`
    #
    # @raise    [Error::Completed]
    #   When the transition has already been marked as completed.
    # @raise    [Error::NotRunning]
    #   When the transition is not running.
    def complete
        fail Error::Completed, 'Transition has completed.'   if completed?
        fail Error::NotRunning, 'Transition is not running.' if !running?

        @time  = Time.now - @clock
        @clock = nil

        self
    end

    # @return   [Integer]   Depth for this transition.
    #
    # @see ZERO_DEPTH
    def depth
        ZERO_DEPTH.include?( event ) ? 0 : 1
    end

    # @param    [Browser]   browser
    #   Browser to use to replay the transition.
    #
    # @return   [Transition, nil]
    #   New transition as a result of the replay, `nil` if the replay wasn't
    #   successful.
    def replay( browser )
        return if !replayable?
        browser.fire_event browser.locate_element( element ), event, options
    end

    # @return   [Bool]
    #   `true` if the transition is in progress, `false` otherwise.
    #
    # @see #initialize
    # @see #start
    # @see #complete
    def running?
        !!@clock
    end

    # @return   [Bool]
    #   `true` if the transition has completed, `false` otherwise.
    #
    # @see #initialize
    # @see #start
    # @see #complete
    def completed?
        !!@time
    end

    # @return   [Bool]
    #   `true` if the transition is for an event that can be replayed, `false`
    #   otherwise.
    #
    # @see NON_REPLAYABLE
    def replayable?
        !NON_REPLAYABLE.include?( event )
    end

    # @return   [String]
    def to_s
        "'#{event}' on: #{element}"
    end

    def dup
        deep_clone
    end

    # @return   [Hash]
    def to_hash
        {
            element: element,
            event:   event,
            options: options,
            time:    time
        }
    end
    alias :to_h :to_hash

    def hash
        to_hash.tap { |h| h.delete :time }.hash
    end

    def ==( other )
        hash == other.hash
    end

end

end
end
end
