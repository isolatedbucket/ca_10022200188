# Deployment Guide - CloudStore

This guide walks you through deploying your CloudStore e-commerce application to production.

## Deployment Architecture

```
Frontend (React)           Backend (Supabase)
      ↓                           ↓
   Vercel                  Managed Cloud
   (Static)              (Already Deployed)
```

## Prerequisites

- GitHub account
- Vercel account (free)
- Supabase project (already set up)
- Code pushed to GitHub repository

## Deployment Steps

### Step 1: Prepare Your Code (5 minutes)

1. **Test locally:**
```bash
npm run build
npm run preview
```

2. **Verify all features work:**
- User registration and login
- Product browsing
- Cart operations
- Order placement
- Admin dashboard (if applicable)

3. **Check environment variables:**
Ensure `.env` has correct Supabase credentials.

### Step 2: Push to GitHub (2 minutes)

1. **Initialize git (if not already):**
```bash
git init
git add .
git commit -m "Initial commit - CloudStore e-commerce app"
```

2. **Create GitHub repository:**
- Go to github.com
- Click "New repository"
- Name it "cloudstore-ecommerce" or similar
- Don't initialize with README (you already have one)

3. **Push code:**
```bash
git remote add origin https://github.com/yourusername/cloudstore-ecommerce.git
git branch -M main
git push -u origin main
```

### Step 3: Deploy to Vercel (5 minutes)

#### A. Connect GitHub to Vercel

1. Go to [vercel.com](https://vercel.com)
2. Sign in with GitHub
3. Click "Add New Project"
4. Select your repository "cloudstore-ecommerce"

#### B. Configure Project

**Framework Preset:** Vite
**Root Directory:** ./
**Build Command:** `npm run build`
**Output Directory:** `dist`

#### C. Add Environment Variables

Click "Environment Variables" and add:

```
VITE_SUPABASE_URL = your_supabase_project_url
VITE_SUPABASE_ANON_KEY = your_supabase_anon_key
```

**Where to find these:**
1. Go to your Supabase project dashboard
2. Click "Settings" → "API"
3. Copy "Project URL" and "anon public" key

#### D. Deploy

1. Click "Deploy"
2. Wait 2-3 minutes for build to complete
3. Your app will be live at: `your-project.vercel.app`

### Step 4: Configure Custom Domain (Optional)

1. In Vercel project settings, go to "Domains"
2. Add your custom domain (e.g., `cloudstore.com`)
3. Update DNS records as instructed by Vercel
4. SSL certificate is automatically provisioned

## Post-Deployment Checklist

### Verify Functionality

- [ ] Home page loads correctly
- [ ] Products display with images
- [ ] User registration works
- [ ] User login works
- [ ] Add to cart functionality
- [ ] Cart page displays items
- [ ] Checkout completes successfully
- [ ] Order history shows orders
- [ ] Admin can access dashboard (if admin user exists)
- [ ] Admin can manage products
- [ ] Admin can update order status

### Test on Multiple Devices

- [ ] Desktop browser (Chrome, Firefox, Safari)
- [ ] Mobile browser (iOS Safari, Chrome)
- [ ] Tablet

### Check Performance

- [ ] Page load time < 3 seconds
- [ ] Images load properly
- [ ] No console errors
- [ ] API calls respond quickly

## Environment-Specific Configuration

### Development
```env
VITE_SUPABASE_URL=https://dev-project.supabase.co
VITE_SUPABASE_ANON_KEY=dev-key
```

### Staging (Optional)
```env
VITE_SUPABASE_URL=https://staging-project.supabase.co
VITE_SUPABASE_ANON_KEY=staging-key
```

### Production
```env
VITE_SUPABASE_URL=https://prod-project.supabase.co
VITE_SUPABASE_ANON_KEY=prod-key
```

## Continuous Deployment

Vercel automatically redeploys when you push to GitHub:

```bash
git add .
git commit -m "Update product catalog"
git push origin main
```

Deployment triggers automatically and completes in 2-3 minutes.

## Rollback Strategy

If deployment has issues:

1. **Vercel Dashboard:**
   - Go to "Deployments"
   - Click "..." on previous working deployment
   - Click "Promote to Production"

2. **Git Revert:**
```bash
git revert HEAD
git push origin main
```

## Database Migration (Supabase)

Database is already deployed. For schema updates:

1. Go to Supabase Dashboard
2. SQL Editor
3. Run migration script
4. Test with staging environment first

## Monitoring & Maintenance

### Vercel Analytics

Enable in project settings:
- Real-time page views
- Performance metrics
- Error tracking

### Supabase Dashboard

Monitor:
- API requests/second
- Database queries
- Edge Function invocations
- Storage usage
- Active users

### Set Up Alerts

**Supabase:**
- Database size approaching limit
- API rate limit warnings
- Edge Function errors

**Vercel:**
- Build failures
- Deployment errors
- Bandwidth usage

## Security Checklist

Before going live:

- [ ] Environment variables are not committed to git
- [ ] `.env` is in `.gitignore`
- [ ] RLS policies are enabled on all tables
- [ ] Admin role assignment is manual (not via API)
- [ ] CORS is properly configured
- [ ] SSL certificate is active (automatic with Vercel)
- [ ] Supabase API keys are for production project

## Performance Optimization

### Implemented Optimizations

- [x] Code splitting with Vite
- [x] Image optimization (external URLs)
- [x] Database indexes
- [x] Lazy loading of components
- [x] localStorage for cart persistence

### Future Optimizations

- [ ] Image CDN (Cloudinary, imgix)
- [ ] Service Worker for offline support
- [ ] Redis caching (for frequent queries)
- [ ] WebP images
- [ ] Lazy loading of product images

## Scaling Considerations

### Current Capacity (Free Tier)

**Vercel:**
- 100GB bandwidth/month
- Unlimited requests
- 100 deployments/day

**Supabase:**
- 500MB database
- 2GB bandwidth/month
- 50k monthly active users
- 2 million Edge Function invocations

### When to Upgrade

**Upgrade Vercel Pro ($20/mo) when:**
- Bandwidth > 100GB/month
- Need custom domains
- Want advanced analytics

**Upgrade Supabase Pro ($25/mo) when:**
- Database > 500MB
- Users > 50k/month
- Need daily backups
- Want dedicated compute

### High Traffic Preparation

For 10,000+ concurrent users:

1. **Database:**
   - Enable connection pooling
   - Add read replicas
   - Optimize expensive queries

2. **Frontend:**
   - Implement CDN for assets
   - Add service worker caching
   - Use skeleton screens for loading states

3. **Backend:**
   - Cache frequent queries
   - Implement rate limiting
   - Scale Edge Functions automatically (handled by Supabase)

## Troubleshooting Deployment

### Build Fails on Vercel

**Check:**
- Node version matches local (18+)
- All dependencies in `package.json`
- Build runs locally: `npm run build`
- TypeScript errors: `npm run typecheck`

**Common fixes:**
```bash
npm run typecheck
npm run lint
npm run build
```

### Environment Variables Not Working

**Verify:**
- Variable names start with `VITE_`
- Values are correct in Vercel dashboard
- Redeployed after adding variables

### Supabase Connection Issues

**Check:**
- URLs don't have trailing slashes
- Keys are from correct project (not local dev)
- API key is "anon/public" not "service role"

### Images Not Loading

**Causes:**
- CORS issues with image host
- Invalid image URLs
- Missing alt attributes

**Fix:**
Use Pexels images (already CORS-enabled) or:
```javascript
crossOrigin="anonymous"
```

### Orders Not Creating

**Debug:**
1. Check browser console for errors
2. Verify JWT token is valid
3. Check Edge Function logs in Supabase
4. Ensure product IDs are correct
5. Verify stock availability

## Backup Strategy

### Automatic Backups (Supabase Pro)

- Daily automatic backups
- 7-day retention
- Point-in-time recovery

### Manual Backup (Free Tier)

1. Go to Supabase Dashboard
2. Database → Backups
3. Click "Create Backup"
4. Download SQL dump

### Code Backups

- Git history on GitHub
- Vercel deployment history
- Local backups: `git clone`

## Cost Estimation

### Free Tier (0-1000 users)

- Vercel: $0/month
- Supabase: $0/month
- **Total: $0/month**

### Small Business (1000-10000 users)

- Vercel Pro: $20/month
- Supabase Pro: $25/month
- **Total: $45/month**

### Growing Business (10000+ users)

- Vercel Pro: $20/month
- Supabase Pro: $25/month
- Additional compute: ~$50/month
- **Total: ~$95/month**

## Production URLs

After deployment, update these in your documentation:

- **Frontend:** `https://your-project.vercel.app`
- **API:** `https://your-project.supabase.co/rest/v1`
- **Auth:** `https://your-project.supabase.co/auth/v1`
- **Edge Functions:** `https://your-project.supabase.co/functions/v1`

## Next Steps After Deployment

1. **Add your first admin user**
   - Register normally
   - Use SQL to promote to admin

2. **Customize product catalog**
   - Remove sample products
   - Add your actual products

3. **Configure email templates** (Supabase)
   - Welcome email
   - Order confirmation
   - Password reset

4. **Set up monitoring**
   - Enable Vercel Analytics
   - Check Supabase metrics daily

5. **Plan for growth**
   - Monitor user growth
   - Track popular products
   - Optimize slow queries

## Support Resources

- **Vercel Docs:** https://vercel.com/docs
- **Supabase Docs:** https://supabase.com/docs
- **Community Discord:** https://discord.supabase.com
- **GitHub Issues:** Create in your repository

## Deployment Checklist Summary

- [ ] Code tested locally
- [ ] Tests passing
- [ ] Environment variables configured
- [ ] Code pushed to GitHub
- [ ] Vercel project created
- [ ] Build successful
- [ ] Production URL accessible
- [ ] All features working
- [ ] Admin user created
- [ ] Custom domain configured (optional)
- [ ] Monitoring enabled
- [ ] Backup strategy in place
- [ ] Documentation updated with production URLs

## Success!

Your CloudStore e-commerce application is now live and accessible to users worldwide!

Monitor the Vercel and Supabase dashboards regularly, and scale resources as your user base grows.
