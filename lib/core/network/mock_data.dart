class MockData {
  // Mock User Profiles
  static final Map<String, dynamic> mockCreatorProfile = {
    'id': 'creator_123',
    'email': 'creator@mock.com',
    'role': 'CREATOR',
    'name': 'Alex Neo',
    'avatar_url': 'https://i.pravatar.cc/150?u=creator1',
    'is_subscribed': true,
    'wallet_balance': 12500,
    'profile_complete': 92,
    'total_campaigns': 8,
    'completed_campaigns': 6,
    'avg_rating': 4.7,
    'response_time': '< 2 hours',
    'connected_platforms': [
      {'platform': 'instagram', 'username': 'alex_neo_ig', 'connected': true},
      {'platform': 'youtube', 'username': 'AlexNeoTech', 'channel_name': 'Alex Neo Tech', 'connected': true}
    ],
    'cached_stats': {
      'instagram': {
        'username': 'alex_neo_ig',
        'profile_picture': 'https://i.pravatar.cc/150?u=creator1',
        'followers_count': 125000,
        'follows_count': 890,
        'media_count': 450,
        'biography': 'Tech • Lifestyle • Reviews 🎬'
      },
      'youtube': {
        'channel_title': 'Alex Neo Tech',
        'channel_url': 'https://youtube.com/c/AlexNeoTech',
        'subscriber_count': '340000',
        'view_count': '15000000',
        'video_count': '120',
        'thumbnail': 'https://i.pravatar.cc/150?u=creator1'
      }
    },
    'creator_profile': {
      'bio': 'Tech reviewer and lifestyle creator with 4+ years of experience partnering with global brands. I create in-depth reviews, setup tours, and lifestyle content that resonates with the 18-34 tech-savvy audience.',
      'headline': 'Tech Creator | 125K on IG | 340K on YT',
      'gender': 'Male',
      'date_of_birth': '1998-03-15',
      'languages': 'English, Hindi',
      'years_experience': 4,
      'content_categories': 'Tech, Gadgets, Lifestyle, Travel',
      'past_brands': 'Samsung, OnePlus, Boat, Noise',
      'city': 'Mumbai',
      'phone': '+91 98765 43210',
      'location': 'Mumbai, Maharashtra',
      'pin_code': '400001',
      'min_budget': 5000,
      'availability_status': 'available',
      'turnaround_days': 3,
      'willing_to_travel': true,
      'rate_card': {
        'instagram_reel': 15000,
        'instagram_story': 5000,
        'instagram_post': 8000,
        'youtube_integration': 25000,
        'youtube_dedicated': 50000,
        'youtube_shorts': 10000
      },
      'social_links': {
        'twitter': 'https://twitter.com/alexneo',
        'linkedin': 'https://linkedin.com/in/alexneo',
        'website': 'https://alexneo.com'
      },
      'audience_demographics': {
        'age_split': {
          '18-24': 45.5,
          '25-34': 30.2,
          '35-44': 15.0,
          '45+': 9.3
        },
        'gender_split': {
          'male': 65.0,
          'female': 30.0,
          'other': 5.0
        },
        'top_cities': 'Mumbai, Bangalore, Delhi',
        'top_countries': 'India, USA, UK'
      },
      'collaboration_prefs': {
        'preferred_categories': 'Tech, Gadgets, Software, SaaS',
        'content_types': 'Reviews, Unboxing, Tutorials, Vlogs',
        'preferred_platforms': 'YouTube, Instagram',
        'min_budget': 5000,
        'preferred_deal': 'Fixed + Performance'
      },
      'past_work': [
        {
          'brand': 'Samsung India',
          'campaign': 'Galaxy S26 Launch',
          'platform': 'YouTube',
          'deliverables': 'Dedicated Review Video',
          'result': '580K views, 24K likes'
        },
        {
          'brand': 'OnePlus',
          'campaign': 'OnePlus 14 Series',
          'platform': 'Instagram',
          'deliverables': '3 Reels + 5 Stories',
          'result': '2.1M reach, 4.8% engagement'
        }
      ]
    }
  };

  static final Map<String, dynamic> mockBrandProfile = {
    'id': 'brand_456',
    'email': 'brand@mock.com',
    'role': 'BRAND',
    'name': 'TechNova',
    'avatar_url': 'https://i.pravatar.cc/150?u=brand1',
    'is_subscribed': true,
    'wallet_balance': 75000,
    'company_name': 'TechNova Electronics',
    'contact_name': 'Ravi Sharma',
    'phone': '+91 99887 65432',
    'role_in_company': 'Head Marketing',
    'website': 'https://technova.in',
    'logo_url': 'https://i.pravatar.cc/150?u=brand1',
    'industry': 'Consumer Electronics',
    'description': 'TechNova Electronics is a leading consumer electronics brand specializing in premium audio gear, smart wearables, and cutting-edge accessories. We partner with top creators to bring authentic reviews and unboxing experiences to our audience.',
    'founded_year': 2019,
    'company_size': '51-200',
    'headquarters': 'Bangalore, India',
    'instagram_url': 'https://instagram.com/technova',
    'twitter_url': 'https://twitter.com/technova',
    'linkedin_url': 'https://linkedin.com/company/technova',
    'product_categories': 'Headphones, Smartwatches, Speakers, TWS Earbuds',
    'target_audience': '18-35, Tech enthusiasts, Gadget lovers, Early adopters',
    'campaign_types': 'Product Reviews, Unboxings, Lifestyle Integration, Giveaways'
  };

  // Mock Jobs / Campaigns Feed (Creator view)
  static final List<Map<String, dynamic>> mockJobFeed = [
    {
      'id': 'job_1',
      'title': 'Tech Review: Quantum Headphones',
      'brand_id': 'brand_456',
      'brand_name': 'TechNova',
      'brand_logo': 'https://i.pravatar.cc/150?u=brand1',
      'budget': 50000,
      'description': 'Looking for a detailed tech review of our new Quantum Noise Cancelling Headphones.',
      'platform': 'youtube',
      'applied': false,
      'requirements': {
        'content_type': 'Dedicated Review Video',
        'key_message': 'Unmatched noise cancellation',
        'hashtags': '#TechNova #QuantumAudio',
        'dos': 'Show the unboxing, test in noisy environments',
        'donts': 'Do not compare negatively with competitors directly'
      }
    },
    {
      'id': 'job_2',
      'title': 'Summer Apparel Launch',
      'brand_id': 'brand_789',
      'brand_name': 'Vibe Clothing',
      'brand_logo': 'https://i.pravatar.cc/150?u=brand2',
      'budget': 20000,
      'description': 'Showcase our new summer collection in a styling reel.',
      'platform': 'instagram',
      'applied': true,
      'requirements': {
        'content_type': 'Instagram Reel',
        'key_message': 'Summer vibes, comfortable fits',
        'hashtags': '#VibeSummer #OOTD',
        'dos': 'Use upbeat trending audio',
        'donts': 'No indoor shots'
      }
    },
    {
      'id': 'job_3',
      'title': 'Fitness App Promotion',
      'brand_id': 'brand_101',
      'brand_name': 'FitPulse',
      'brand_logo': 'https://i.pravatar.cc/150?u=brand3',
      'budget': 15000,
      'description': 'Post a tweet thread about how FitPulse helps track daily macros easily.',
      'platform': 'twitter',
      'applied': false,
      'requirements': {
        'content_type': 'Twitter Thread',
        'key_message': 'Simplifying macro tracking',
        'hashtags': '#FitPulse #FitnessJourney',
        'dos': 'Include screenshots of the app UI',
        'donts': "Don't make medical claims"
      }
    }
  ];

  // Mock Brand Campaigns (Brand view)
  static final List<Map<String, dynamic>> mockBrandCampaigns = [
    {
      'id': 'camp_1',
      'title': 'Quantum Headphones Launch',
      'status': 'ACTIVE',
      'budget': 150000,
      'description': 'Mega campaign for our flagship headphones.',
      'platform': 'youtube',
      'applications_count': 12,
      'requirements': {
        'content_type': 'Review Video',
        'hashtags': '#QuantumAudio'
      }
    },
    {
      'id': 'camp_2',
      'title': 'Smartwatch Micro-influencers',
      'status': 'CLOSED',
      'budget': 40000,
      'description': 'Instagram stories campaign.',
      'platform': 'instagram',
      'applications_count': 45,
      'requirements': {
        'content_type': 'Stories',
        'hashtags': '#TechNovaWatch'
      }
    }
  ];

  // Mock Conversations (Shared)
  static final List<Map<String, dynamic>> mockConversations = [
    {
      'id': 'conv_1',
      'participant_name': 'TechNova',
      'participant_avatar': 'https://i.pravatar.cc/150?u=brand1',
      'last_message': 'Great! Looking forward to the draft.',
      'updated_at': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
    },
    {
      'id': 'conv_2',
      'participant_name': 'Vibe Clothing',
      'participant_avatar': 'https://i.pravatar.cc/150?u=brand2',
      'last_message': 'Can you change the audio track?',
      'updated_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
    }
  ];

  // Mock Messages for a conversation
  static final List<Map<String, dynamic>> mockMessages = [
    {
      'id': 'msg_1',
      'sender_id': 'brand_456',
      'text': 'Hi Alex! We loved your profile. Are you available for the Quantum campaign?',
      'created_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
    },
    {
      'id': 'msg_2',
      'sender_id': 'creator_123',
      'text': 'Yes, absolutely! I use TechNova gear all the time.',
      'created_at': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
    },
    {
      'id': 'msg_3',
      'sender_id': 'brand_456',
      'text': 'Great! Looking forward to the draft.',
      'created_at': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
    }
  ];

  // Mock Applications (Creator view)
  static final List<Map<String, dynamic>> mockApplications = [
    {
      'id': 'app_1',
      'job_id': 'job_2',
      'job_title': 'Summer Apparel Launch',
      'brand_name': 'Vibe Clothing',
      'status': 'PENDING',
      'proposed_rate': 25000,
      'cover_letter': 'I love your summer collection and my audience perfectly aligns with your demographic.',
      'applied_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    }
  ];

  static Map<String, dynamic> generateAuthResponse(String role) {
    return {
      'token': 'mock_jwt_token_${role.toLowerCase()}',
      'user': role == 'BRAND' ? mockBrandProfile : mockCreatorProfile,
    };
  }

  // Mock Analytics Data
  static final Map<String, dynamic> mockCreatorAnalytics = {
    'instagram': {
      'tier': 'Gold',
      'engagement_rate': 4.8,
      'avg_views': 45000,
      'avg_likes': 8500,
      'avg_comments': 420,
      'avg_shares': 1200,
      'avg_saves': 800,
      'avg_reach': 60000,
      'reach_28d': 1200000,
      'impressions_28d': 2500000,
      'profile_views_28d': 45000,
      'trend_data': {
        'profile_views_7d': [3200, 4100, 3800, 5200, 4600, 6100, 5800],
        'likes_7d': [7200, 8100, 9400, 7800, 10200, 8900, 9600],
        'reach_7d': [42000, 51000, 48000, 62000, 55000, 68000, 61000],
        'impressions_7d': [85000, 96000, 91000, 110000, 105000, 125000, 118000],
        'profile_views_30d': [
          2100, 2500, 2800, 3100, 2700, 3400, 3000,
          3200, 4100, 3800, 5200, 4600, 3900, 4200,
          4800, 5100, 4500, 5600, 5200, 4900, 5400,
          5800, 6200, 5500, 6800, 6100, 5900, 6400,
          6100, 5800
        ],
        'likes_30d': [
          5200, 5800, 6100, 5500, 6400, 7000, 6800,
          7200, 8100, 9400, 7800, 10200, 8900, 7600,
          8200, 8800, 9100, 8600, 9500, 10100, 9800,
          10400, 11200, 10800, 11500, 10900, 11800, 12200,
          9600, 10200
        ],
        'reach_30d': [
          28000, 31000, 34000, 30000, 36000, 38000, 35000,
          42000, 51000, 48000, 62000, 55000, 46000, 49000,
          52000, 56000, 54000, 59000, 63000, 61000, 58000,
          65000, 70000, 67000, 72000, 68000, 66000, 71000,
          61000, 64000
        ]
      }
    },
    'youtube': {
      'tier': 'Platinum',
      'engagement_rate': 6.2,
      'avg_views': 120000,
      'avg_likes': 15000,
      'avg_comments': 1200,
      'avg_duration': 450,
      'total_views': 15000000,
      'video_count': 120,
      'channel_age_years': 4,
      'country': 'India',
      'analytics_28d': {
        'estimatedMinutesWatched': 1500000.0,
        'averageViewDuration': 310.0,
        'averageViewPercentage': 45.5,
        'impressions': 5000000.0,
        'impressionClickThroughRate': 0.085,
        'shares': 25000.0,
        'subscribersGained': 8500.0,
        'subscribersLost': 1200.0,
        'likes': 150000.0
      },
      'trend_data': {
        'views_7d': [95000, 110000, 125000, 98000, 140000, 135000, 128000],
        'likes_7d': [12000, 14500, 16200, 13000, 18000, 17200, 15800],
        'subscribers_7d': [850, 1100, 1250, 900, 1400, 1350, 1200],
        'views_30d': [
          65000, 72000, 78000, 70000, 82000, 88000, 85000,
          95000, 110000, 125000, 98000, 140000, 135000, 105000,
          112000, 118000, 125000, 115000, 130000, 138000, 132000,
          142000, 155000, 148000, 160000, 152000, 158000, 165000,
          128000, 145000
        ],
        'likes_30d': [
          8000, 9200, 10100, 9000, 10800, 11500, 11200,
          12000, 14500, 16200, 13000, 18000, 17200, 13800,
          14500, 15200, 16000, 14800, 16500, 17500, 17000,
          18200, 19800, 19000, 20500, 19500, 20000, 21000,
          15800, 18500
        ]
      }
    }
  };

  // Mock List of Creators for Search and Spotlight
  static final List<Map<String, dynamic>> mockCreatorsList = [
    {
      'id': 'creator_1',
      'name': 'Alex Neo',
      'avatar_url': 'https://i.pravatar.cc/150?u=creator1',
      'niche': 'Tech',
      'city': 'San Francisco',
      'verified': true,
      'min_budget': 25000,
      'engagement_rate': 4.8,
      'avg_views': 45000,
      'avg_likes': 8500,
      'response_time_hours': 6,
      'instagram_username': 'alexneo_tech',
      'youtube_channel_id': 'UCAlexNeo',
      'instagram_followers': 125000,
      'youtube_subscribers': 340000,
      'cached_stats': {
        'instagram': {'profile_picture': 'https://i.pravatar.cc/150?u=creator1'},
        'youtube': {'thumbnail': 'https://i.pravatar.cc/150?u=creator1'}
      }
    },
    {
      'id': 'creator_2',
      'name': 'Mia Style',
      'avatar_url': 'https://i.pravatar.cc/150?u=creator2',
      'niche': 'Fashion',
      'city': 'New York',
      'verified': true,
      'min_budget': 50000,
      'engagement_rate': 6.2,
      'avg_views': 320000,
      'avg_likes': 52000,
      'response_time_hours': 12,
      'instagram_username': 'miastyle',
      'instagram_followers': 850000,
      'youtube_subscribers': 12000,
      'cached_stats': {
        'instagram': {'profile_picture': 'https://i.pravatar.cc/150?u=creator2'}
      }
    },
    {
      'id': 'creator_3',
      'name': 'Laugh Out Loud',
      'avatar_url': 'https://i.pravatar.cc/150?u=creator3',
      'niche': 'Comedy',
      'city': 'London',
      'verified': false,
      'min_budget': 75000,
      'engagement_rate': 3.1,
      'avg_views': 480000,
      'avg_likes': 38000,
      'response_time_hours': 24,
      'youtube_channel_id': 'UCLaughOutLoud',
      'instagram_followers': 45000,
      'youtube_subscribers': 1500000,
      'cached_stats': {
        'youtube': {'thumbnail': 'https://i.pravatar.cc/150?u=creator3'}
      }
    },
    {
      'id': 'creator_4',
      'name': 'Travel with Sam',
      'avatar_url': 'https://i.pravatar.cc/150?u=creator4',
      'niche': 'Travel',
      'city': 'Bali',
      'verified': true,
      'min_budget': 35000,
      'engagement_rate': 5.4,
      'avg_views': 180000,
      'avg_likes': 22000,
      'response_time_hours': 8,
      'instagram_username': 'travelsam',
      'youtube_channel_id': 'UCTravelSam',
      'instagram_followers': 450000,
      'youtube_subscribers': 210000,
      'cached_stats': {
        'instagram': {'profile_picture': 'https://i.pravatar.cc/150?u=creator4'},
        'youtube': {'thumbnail': 'https://i.pravatar.cc/150?u=creator4'}
      }
    }
  ];

  // Mock Creator Media (Instagram + YouTube posts)
  static Map<String, dynamic> mockCreatorMedia(String? platform) {
    final igMedia = [
      {
        'id': 'ig_1',
        'title': 'Sunset in Bali 🌅',
        'thumbnail_url': 'https://picsum.photos/seed/ig1/400/400',
        'permalink': 'https://www.instagram.com/p/mock1',
        'media_type': 'IMAGE',
        'like_count': 12400,
        'view_count': null,
        'timestamp': '2026-04-28T14:30:00Z',
      },
      {
        'id': 'ig_2',
        'title': 'New tech unboxing 📦',
        'thumbnail_url': 'https://picsum.photos/seed/ig2/400/400',
        'permalink': 'https://www.instagram.com/p/mock2',
        'media_type': 'VIDEO',
        'like_count': 8700,
        'view_count': 45000,
        'timestamp': '2026-04-25T10:15:00Z',
      },
      {
        'id': 'ig_3',
        'title': 'Coffee & Code ☕',
        'thumbnail_url': 'https://picsum.photos/seed/ig3/400/400',
        'permalink': 'https://www.instagram.com/p/mock3',
        'media_type': 'IMAGE',
        'like_count': 9300,
        'view_count': null,
        'timestamp': '2026-04-22T08:00:00Z',
      },
      {
        'id': 'ig_4',
        'title': 'OOTD vibes 🔥',
        'thumbnail_url': 'https://picsum.photos/seed/ig4/400/400',
        'permalink': 'https://www.instagram.com/p/mock4',
        'media_type': 'IMAGE',
        'like_count': 15200,
        'view_count': null,
        'timestamp': '2026-04-19T16:45:00Z',
      },
      {
        'id': 'ig_5',
        'title': 'Behind the scenes 🎬',
        'thumbnail_url': 'https://picsum.photos/seed/ig5/400/400',
        'permalink': 'https://www.instagram.com/p/mock5',
        'media_type': 'VIDEO',
        'like_count': 6800,
        'view_count': 32000,
        'timestamp': '2026-04-16T12:00:00Z',
      },
    ];

    final ytMedia = [
      {
        'id': 'yt_1',
        'title': 'iPhone 18 Pro - Full Review',
        'thumbnail_url': 'https://picsum.photos/seed/yt1/480/270',
        'permalink': 'https://www.youtube.com/watch?v=mock1',
        'media_type': 'YOUTUBE',
        'like_count': 24000,
        'view_count': 580000,
        'timestamp': '2026-04-30T18:00:00Z',
      },
      {
        'id': 'yt_2',
        'title': 'Best Budget Laptops 2026',
        'thumbnail_url': 'https://picsum.photos/seed/yt2/480/270',
        'permalink': 'https://www.youtube.com/watch?v=mock2',
        'media_type': 'YOUTUBE',
        'like_count': 18500,
        'view_count': 420000,
        'timestamp': '2026-04-26T14:00:00Z',
      },
      {
        'id': 'yt_3',
        'title': 'My Desk Setup Tour 2026',
        'thumbnail_url': 'https://picsum.photos/seed/yt3/480/270',
        'permalink': 'https://www.youtube.com/watch?v=mock3',
        'media_type': 'YOUTUBE',
        'like_count': 31000,
        'view_count': 750000,
        'timestamp': '2026-04-20T10:00:00Z',
      },
      {
        'id': 'yt_4',
        'title': 'Is This the Future of AI?',
        'thumbnail_url': 'https://picsum.photos/seed/yt4/480/270',
        'permalink': 'https://www.youtube.com/watch?v=mock4',
        'media_type': 'YOUTUBE',
        'like_count': 42000,
        'view_count': 1200000,
        'timestamp': '2026-04-15T20:00:00Z',
      },
    ];

    if (platform == 'instagram') return {'instagram': igMedia};
    if (platform == 'youtube') return {'youtube': ytMedia};
    return {'instagram': igMedia, 'youtube': ytMedia};
  }
}
