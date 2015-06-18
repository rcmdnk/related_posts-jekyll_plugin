module Jekyll
  class RelatedPostsGenerator < Generator
    safe :true
    priority :lower

    # Calculate related posts.
    # Returns [<Post>]
    def related_posts(me, posts)
      return [] unless posts.size > 1
      highest_freq = @tag_freq.values.max
      related_scores = Hash.new(0)

      posts.each do |post|
        post.tags.each do |tag|
          if me.tags.include?(tag) && post != me
            cat_freq = @tag_freq[tag]
            related_scores[post] += (1+highest_freq-cat_freq)
          end
        end
      end

      sort_related_posts(related_scores)
    end

    # Calculate the frequency of each tag.
    # Returns {tag => freq, tag => freq, ...}
    def tag_freq(posts)
      @tag_freq = Hash.new(0)
      posts.each do |post|
        post.tags.each {|tag| @tag_freq[tag] += 1}
      end
    end

    # Sort the related posts in order of their score and date
    # and return just the posts
    def sort_related_posts(related_scores)
      related_scores.sort do |a,b|
        if a[1] < b[1]
          1
        elsif a[1] > b[1]
          -1
        else
          b[0].date <=> a[0].date
        end
      end.collect {|post,freq| post}
    end

    def generate(site)
      if !site.config['related_posts']
        return
      end
      n_posts = site.config['related_posts']
      tag_freq(site.posts)
      Parallel.map(site.posts.flatten, :in_threads => site.config['n_cores'] ? site.config['n_cores'] : 1) do |post|
        rp = related_posts(post, site.posts)[0, n_posts]
        if rp.size > 0
          post.data.merge!('related_posts' => rp)
        end
      end
    end
  end
end
