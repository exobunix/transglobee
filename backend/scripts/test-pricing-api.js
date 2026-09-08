const pricingController = require("../controllers/pricingController");

async function testPricing() {
  const req = {
    body: {
      pickup: { lat: 18.9220, lng: 72.8347, address: "Apollo Bandar, Mumbai" },
      dropoff: { lat: 19.0760, lng: 72.8777, address: "Bandra, Mumbai" },
      serviceType: "ride"
    }
  };

  const res = {
    status: function (code) {
      this.statusCode = code;
      return this;
    },
    json: function (data) {
      console.log("Pricing API Test Output (Status " + this.statusCode + "):");
      console.log(JSON.stringify(data, null, 2));
    }
  };

  await pricingController.estimateFare(req, res);
}

testPricing();
