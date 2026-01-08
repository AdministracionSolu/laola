import { Layout } from "@/components/layout/Layout";
import { HeroSection } from "@/components/home/HeroSection";
import { FeaturedDishes } from "@/components/home/FeaturedDishes";
import { EventsSection } from "@/components/home/EventsSection";
import { LocationsPreview } from "@/components/home/LocationsPreview";

const Index = () => {
  return (
    <Layout>
      <HeroSection />
      <FeaturedDishes />
      <EventsSection />
      <LocationsPreview />
    </Layout>
  );
};

export default Index;
