User.create(username:'system', display_name: 'System', active: false)
p "Created seed users."

Group.create(name:'Default', slack_channel: '#general', default: true)
p "Created seed group."

Reward.create(name:'Air Lounge Coupon', cost: 40, stock_count: Reward::INFINITE_STOCK, visible: true)
Reward.create(name:'Quẩy cạn lời 500k', cost: 600, stock_count: Reward::INFINITE_STOCK, visible: true)
Reward.create(name:'Quẩy khô máu 1000k', cost: 1100, stock_count: Reward::INFINITE_STOCK, visible: true)
Reward.create(name:'Quẩy tẹt ga', cost: 10000, stock_count: 1, visible: true)
Reward.create(name:'Silicon Straits Cup', cost: 100, stock_count: 15, visible: true)
Reward.create(name:'Silicon Straits Notebook', cost: 100, stock_count: 18, visible: true)
Reward.create(name:'T-shirt', cost: 300, stock_count: Reward::INFINITE_STOCK, visible: true)
p "Created seed rewards."
