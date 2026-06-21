# Railway Token — required for GitHub Actions deploy workflow

# Generate a Railway token:
#   railway token
#
# Or via Railway dashboard:
#   Settings → API Tokens → Create Token
#
# Set as GitHub secret:
#   gh secret set RAILWAY_TOKEN --repo sambawy01/Hermes-PA
#
# This token allows the deploy.yml workflow to deploy to Railway
# from GitHub Actions (PRs → staging, pushes to main → production).