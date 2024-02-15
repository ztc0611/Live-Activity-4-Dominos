# Live Activty for Dominos Pizza
 Using this app, a countdown timer based on live data can be initated from your phone. This will show the minimum and maximum number of time left until your order is ready. This works on both delivery and pickup orders in the US.

 ![image](https://github.com/ztc0611/Live-Dominos-Pizza/assets/28269330/232ae196-e84b-4b70-954b-719102e850e2)
 ![image](https://github.com/ztc0611/Live-Dominos-Pizza/assets/28269330/d646000c-ac51-4562-90ea-b99f7e68137d)

## How does this work?

As of the creation of this app, the Dominos API is not locked down, and can be accesed publically. By typing in the (10 digit) phone number associated with the order and hitting start, it is able to access the tracking data of the order. 

None of this information ever goes to a place I can access, it is just between you and the Dominos server.

## How can I use it?

This will require you to "sideload" the app via Xcode. Download the project zip, open it in Xcode, and configure sending it to your device. Depending on if you have a free or paid developer account, the amount of time the app stays possible to use changes. It also works correctly in the simulator. 

Once you have it on your device, make an order, then type in your phone number and hit start.

## Why not the full tracker? / Why no automatic start?

Adding the full tracker would require a server, as you cannot update a live activity in the way required without push notifications. Even if one was set up and paid for, the server would likely be banned for spamming polling requests to their website.
